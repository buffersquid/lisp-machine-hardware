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
  typedef logic [11:0] address_t;

  typedef enum logic [3:0] {
    SelectExpr,
    Fetch,
    MemWait,
    EvalConst,
    EvalCar,
    Apply,
    Halt,
    Error
  } state_t;

  typedef struct packed {
    logic     active;
    address_t address;
    state_t   continue_state;
  } memory_read_t;

  // Error codes
  localparam logic [15:0] STATE_ERROR = 16'h6666;
  localparam logic [15:0] FETCH_ERROR = 16'hAAAA;

  //────────────────────────────────────────────────────────────
  // Registers
  //────────────────────────────────────────────────────────────
  logic [15:0] expr = 16'h0000;
  logic [15:0] expr_next;
  logic [15:0] val = 16'h0000;
  logic [15:0] val_next;
  logic [15:0] error = 16'h0000;
  logic [15:0] error_next;

  //────────────────────────────────────────────────────────────
  // Memory
  //────────────────────────────────────────────────────────────
  logic [15:0] mem_data;
  logic        mem_ready;
  memory mem (
    .clk(clk),
    .rst(rst),
    .req(memory_read.active),
    .addr_in(memory_read.address),
    .data_ready(mem_ready),
    .data_out(mem_data)
  );

  //────────────────────────────────────────────────────────────
  // Seven-segment display
  //────────────────────────────────────────────────────────────
  seven_segment ssg (
    .clk(clk),
    .hex(val),
    .cathodes(cathodes),
    .anodes(anodes)
  );

  //────────────────────────────────────────────────────────────
  // Combinational FSM Logic
  //────────────────────────────────────────────────────────────
  state_t state = SelectExpr;
  state_t state_next, after_read;

  logic [15:0] user_expr;
  logic        go_pressed, go_prev;

  memory_read_t memory_read;
  always_comb begin
    // Default memory request (inactive)
    memory_read.active = 1'b0;
    memory_read.address = '0;
    memory_read.continue_state = state;

    state_next = state; // default, stay in the same state
    expr_next = expr;
    val_next = val;
    error_next = error;

    user_expr = switches;
    leds = 16'b0000;

    case (state)

      SelectExpr: begin
        val_next = switches;
        if (go_pressed) begin
          val_next = 16'h0000;
          expr_next = switches;
          state_next = Fetch;
        end else begin
          state_next = SelectExpr;
        end
      end

      Fetch: begin
        case (expr[14:12])
          lisp_defs::TYPE_NUMBER: begin
            memory_read.active = 1'b1;
            memory_read.address = expr[11:0];
            memory_read.continue_state = EvalConst;
            state_next = MemWait;
          end
          lisp_defs::TYPE_CONS: begin
            memory_read.active = 1'b1;
            memory_read.address = expr[11:0];  // car is at base address
            memory_read.continue_state = Apply;
            state_next = MemWait;
          end
          default: begin
            error_next = FETCH_ERROR;
            state_next = Error;
          end
        endcase
      end

      MemWait: begin
        if (mem_ready) state_next = after_read;
      end

      EvalConst: begin
        val_next = mem_data;
        state_next = Halt;
      end

      EvalCar: begin
        expr_next = mem_data;
        state_next = Fetch;
      end

      Apply: begin
        // We came from a cons (a . b), but we need to know if the first
        // symbol is a primitive/function/proc or an atom (number)
        case (mem_data[14:11])
          lisp_defs::TYPE_NUMBER: begin
            val_next = expr;
            state_next = Halt;
          end
        endcase
      end

      Halt: leds = {{15{1'b0}}, 1'b1};
      Error: leds = error;
      default: leds = STATE_ERROR;
    endcase
  end

  //────────────────────────────────────────────────────────────
  // Clocked State & Continuation Update
  //────────────────────────────────────────────────────────────
  always_ff @(posedge clk) begin
    if (rst) begin
      state      <= SelectExpr;
      after_read <= SelectExpr;
      expr       <= 16'h0000;
      val        <= 16'h0000;
      error      <= 16'h0000;
    end else begin
      if (memory_read.active) begin
        after_read <= memory_read.continue_state;
      end
      state <= state_next;
      expr  <= expr_next;
      val   <= val_next;
      error <= error_next;
    end
  end

  // For latching the expr user input
  always_ff @(posedge clk) begin
    go_prev    <= btn_start;
    go_pressed <= btn_start & ~go_prev; // Edge detection
  end

endmodule
