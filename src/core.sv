`timescale 1ns / 1ps
`default_nettype none

`include "lisp.sv"

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
  task automatic send_error(
    input logic [3:0] error
  );
  begin
    error_code = error;
    state.next = lisp::Error;
  end
  endtask

  //────────────────────────────────────────────────────────────
  // Registers
  //────────────────────────────────────────────────────────────
  typedef struct packed {
    logic [lisp::word_size:0] current;
    logic [lisp::word_size:0] next;
  } reg_t;
  reg_t expr;
  reg_t val;

  //────────────────────────────────────────────────────────────
  // Memory
  //────────────────────────────────────────────────────────────
  logic active_read;
  logic [lisp::word_size:0] addr_in_latch;
  // Inputs
  logic [lisp::word_size:0] addr_in;
  // Outputs
  logic [lisp::word_size:0] mem_out;

  memory mem (
    .clk(clk),
    .addr_in(addr_in_latch),
    .data_out(mem_out)
  );

  //────────────────────────────────────────────────────────────
  // Seven-segment display
  //────────────────────────────────────────────────────────────
  logic [15:0] display_value;
  assign display_value = (state.current == lisp::SelectExpr) ? switches : val.current;
  seven_segment ssg (
    .clk(clk),
    .hex(display_value),
    .error(state.current == lisp::Error),
    .error_code(error_code_reg),
    .cathodes(cathodes),
    .anodes(anodes)
  );

  //────────────────────────────────────────────────────────────
  // Combinational FSM Logic
  //────────────────────────────────────────────────────────────
  struct packed {
    lisp::state_t current;
    lisp::state_t next;
  } state;

  logic go_pressed, go_prev;

  logic entering_error_state;
  assign entering_error_state = (state.current != lisp::Error) && (state.next == lisp::Error);

  always_comb begin
    state.next = state.current;
    val.next   = val.current;

    active_read = 1'b0;
    addr_in = 'h0;

    leds = 16'b0000;
    // Tehnically, this is a STATE ERROR, but it doesn't really matter if we
    // don't get into the error state.
    error_code = 4'h0;

    case (state.current)

      lisp::SelectExpr: begin
        if (go_pressed) begin
          addr_in = switches;
          active_read = 1'b1;
          state.next = lisp::MemWait;
        end else begin
          state.next = lisp::SelectExpr;
        end
      end

      lisp::MemWait: state.next = lisp::Eval;

      // Determines what kind of thing the expr is, and what to do with it
      lisp::Eval: begin
        val.next = mem_out;
        state.next = lisp::Halt;
      end

      lisp::Halt: leds = LED_HALT;

      lisp::Error: begin
        leds = LED_ERROR;
        state.next = lisp::Error;
      end

      default: send_error(STATE_ERROR);
    endcase
  end

  //────────────────────────────────────────────────────────────
  // Clocked State & Continuation Update
  //────────────────────────────────────────────────────────────
  always_ff @(posedge clk) begin
    if (rst) begin
      state.current <= lisp::SelectExpr;
      val.current   <= lisp::SelectExpr;
    end else begin
      state.current <= state.next;
      val.current   <= val.next;

      if (active_read) begin
        addr_in_latch <= addr_in;
      end

      if (entering_error_state) begin
        error_code_reg <= error_code; //Latch the error
      end
    end
  end

  // For latching the expr user input
  always_ff @(posedge clk) begin
    go_prev    <= btn_start;
    go_pressed <= btn_start & ~go_prev; // Edge detection
  end

endmodule
