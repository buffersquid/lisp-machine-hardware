`timescale 1ns / 1ps
`default_nettype none

`include "lisp_defs.sv"

module core (
  input  wire         clk,
  input  wire         rst,
  input  wire         btn_start,
  input  wire  [15:0] switches,
  output logic [ 7:0] cathodes,
  output logic [ 3:0] anodes,
  output logic [15:0] leds
);
  //────────────────────────────────────────────────────────────
  // Types
  //────────────────────────────────────────────────────────────
  typedef logic [15:0] address_t;

  typedef enum {
    SelectExpr,
    Fetch,
    MemWait,
    Eval,
    EvalArgs,
    Apply,
    ApplyArgs,
    Halt,
    Error
  } state_t;

  // Error codes
  localparam logic [ 3:0] STATE_ERROR = 4'h0;
  localparam logic [ 3:0] FETCH_ERROR = 4'h1;
  localparam logic [ 3:0] EVAL_ERROR  = 4'h2;
  localparam logic [ 3:0] APPLY_ERROR = 4'h3;
  localparam logic [15:0] LED_ERROR   = 16'hFFFF;
  localparam logic [15:0] LED_HALT    = 16'h0001;
  logic [3:0]  error_code, error_code_reg;

  //────────────────────────────────────────────────────────────
  // Functions & Tasks
  //────────────────────────────────────────────────────────────
  task automatic read_mem(
    input address_t addr,
    input state_t next_state
  );
    begin
      memory_read.active         = 1'b1;
      memory_read.addr           = addr;
      memory_read.continue_state = next_state;
      state.next = MemWait;
    end
  endtask

  task automatic send_error(
    input logic [3:0] error
  );
  begin
    error_code = error;
    state.next = Error;
  end
  endtask

  //────────────────────────────────────────────────────────────
  // Registers
  //────────────────────────────────────────────────────────────
  typedef struct packed {
    logic [15:0] current;
    logic [15:0] next;
  } reg_t;
  reg_t expr, val, args;

  //────────────────────────────────────────────────────────────
  // Memory
  //────────────────────────────────────────────────────────────
  struct packed {
    logic active;
    address_t addr;
    logic mem_ready;
    state_t continue_state;
  } memory_read;

  logic [15:0] memory_addr_latched;
  logic [15:0] mem_car, mem_cdr;
  // slicing off the GC bit. I don't think core needs to worry about that
  logic [14:0] mem_header;

  memory mem (
    .clk(clk),
    .rst(rst),
    .read_enable(memory_read.active),
    .addr_in(memory_addr_latched),
    .header_out(mem_header),
    .car_out(mem_car),
    .cdr_out(mem_cdr),
    .done(memory_read.mem_ready)
  );

  //────────────────────────────────────────────────────────────
  // Seven-segment display
  //────────────────────────────────────────────────────────────
  logic [15:0] display_value;
  assign display_value = (state.current == SelectExpr) ? switches : val.current;
  seven_segment ssg (
    .clk(clk),
    .hex(display_value),
    .error(state.current == Error),
    .error_code(error_code_reg),
    .cathodes(cathodes),
    .anodes(anodes)
  );

  //────────────────────────────────────────────────────────────
  // Combinational FSM Logic
  //────────────────────────────────────────────────────────────
  struct packed {
    state_t current;
    state_t next, after_read;
  } state;

  logic go_pressed, go_prev;

  logic entering_error_state;
  assign entering_error_state = (state.current != Error) && (state.next == Error);


  always_comb begin
    state.next = state.current;
    expr.next  = expr.current;
    val.next   = val.current;
    args.next  = args.current;

    leds = 16'b0000;
    // Tehnically, this is a STATE ERROR, but it doesn't really matter if we
    // don't get into the error state.
    error_code = 4'h0;

    memory_read.active = 1'b0;
    memory_read.addr   = 0;
    memory_read.continue_state = state.current;

    case (state.current)

      SelectExpr: begin
        if (go_pressed) begin
          expr.next = switches;
          state.next = Fetch;
        end else begin
          state.next = SelectExpr;
        end
      end

      MemWait: begin
        if (memory_read.mem_ready) state.next = state.after_read;
      end

      Fetch: read_mem(expr.current, Eval);

      // Determines what kind of thing the expr is, and what to do with it
      Eval: begin
        case (mem_header)
          lisp_defs::TYPE_NUMBER: begin
            // This evaluation is jank. What we really need to do is start
            // dealing with CLINK variables. However, since I just want to get
            // numbers to work for now, we are going to do this simple
            // version.
            val.next = mem_car;
            state.next = Halt;
          end

          lisp_defs::TYPE_CONS: begin
            // It's a TYPE_CONS, so it's a procedure of some sort
            // Need to find the operator and save the arguments
            args.next = mem_cdr;
            val.next  = 0;
            read_mem(mem_car, Apply);
          end
        default: send_error(EVAL_ERROR);
        endcase
      end

      // Determines what kind of thing the memory response is, and what to do
      // with it. Differs from Eval, in that we don't set val = 0. Supposed to
      // be for evaluating arguments of some root operator. However, I'm not
      // 100% sold on this as it seems like we may be able to reuse other
      // functionality instead of having new states.
      //
      // WARNING: We have no checking going on for this. So it can literally
      // only evaluate (+ number number number number ...). Any other input
      // will bork the system.
      EvalArgs: begin
        case (mem_header)
          lisp_defs::TYPE_CONS: begin
            args.next = mem_cdr;
            read_mem(mem_car, ApplyArgs);
          end
        endcase
      end

      // Takes a function and a list of evaluated args and applies the
      // function to those arguments
      Apply: begin
        case (mem_header)
          lisp_defs::TYPE_PRIMITIVE: begin
            // Save the primop code in expression for now. Will probably need
            // to change once we get recursive evaluation going.
            expr.next = mem_car;
            read_mem(args.current, EvalArgs);
          end
          default: send_error(APPLY_ERROR);
        endcase
      end

      // Using the latched top-level function, determine what to do with the
      // data. For example, if the top-level funciton is an add, then we want
      // to add val (which is acting as an accumulator) and the car of the
      // memory response (which we are assuming to be a number, and thus the
      // car holds the data).
      //
      // Once we do the prodecure, then we go back to EvalArgs, but this time
      // with the next argument in the list, which is set in EvalArgs.
      //
      // Finally, when we see that the arg is nil, we know we have reached the
      // end of the list, and go to halt.
      ApplyArgs: begin
        case (expr.current)
          lisp_defs::PRIMOP_ADD: begin
            val.next = val.current + mem_car;
            if (args.current == lisp_defs::LISP_NIL) begin
              state.next = Halt;
            end else begin
              read_mem(args.current, EvalArgs);
            end
          end
        endcase
      end

      Halt: leds = LED_HALT;

      Error: begin
        leds = LED_ERROR;
        state.next = Error;
      end

      default: send_error(STATE_ERROR);
    endcase
  end

  //────────────────────────────────────────────────────────────
  // Clocked State & Continuation Update
  //────────────────────────────────────────────────────────────
  always_ff @(posedge clk) begin
    if (rst) begin
      state.current    <= SelectExpr;
      state.after_read <= SelectExpr;
      expr.current     <= lisp_defs::LISP_NIL;
      val.current      <= lisp_defs::LISP_NIL;
      args.current      <= lisp_defs::LISP_NIL;
      error_code_reg   <= 4'h0;
    end else begin
      state.current <= state.next;
      expr.current  <= expr.next;
      val.current   <= val.next;
      args.current   <= args.next;

      if (entering_error_state) begin
        error_code_reg <= error_code; //Latch the error
      end

      if (memory_read.active) begin
        memory_addr_latched <= memory_read.addr;
        state.after_read    <= memory_read.continue_state;
      end
    end
  end

  // For latching the expr user input
  always_ff @(posedge clk) begin
    go_prev    <= btn_start;
    go_pressed <= btn_start & ~go_prev; // Edge detection
  end

endmodule
