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
    Apply,
    Halt,
    Error
  } state_t;

  // Error codes
  localparam logic [15:0] STATE_ERROR = 16'h6666;
  localparam logic [15:0] FETCH_ERROR = 16'hAAAA;
  localparam logic [15:0] EVAL_ERROR  = 16'hBBBB;
  localparam logic [15:0] APPY_ERROR  = 16'hCCCC;

  //────────────────────────────────────────────────────────────
  // Registers
  //────────────────────────────────────────────────────────────
  typedef struct packed {
    logic [15:0] current;
    logic [15:0] next;
  } reg_t;
  reg_t expr, val, error;

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

  always_comb begin
    state.next = state.current;
    expr.next  = expr.current;
    val.next   = val.current;
    error.next = error.current;

    leds = 16'b0000;

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

      Fetch: begin
        memory_read.active         = 1'b1;
        memory_read.addr           = expr.current;
        memory_read.continue_state = Eval;
        state.next = MemWait;
      end

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
        default: begin
          error.next = EVAL_ERROR;
          state.next = Error;
        end
        endcase
      end

      // Takes a function and a list of evaluated args and applies the
      // function to those arguments
      Apply: begin
      end

      Halt: leds = {{15{1'b0}}, 1'b1};
      Error: leds = error.current;
      default: leds = STATE_ERROR;
    endcase
  end

  //────────────────────────────────────────────────────────────
  // Clocked State & Continuation Update
  //────────────────────────────────────────────────────────────
  always_ff @(posedge clk) begin
    if (rst) begin
      state.current    <= SelectExpr;
      state.after_read <= SelectExpr;
      expr.current  <= lisp_defs::LISP_NIL;
      val.current   <= lisp_defs::LISP_NIL;
      error.current <= lisp_defs::LISP_NIL;
    end else begin
      state.current <= state.next;
      expr.current  <= expr.next;
      val.current   <= val.next;
      error.current <= error.next;

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
