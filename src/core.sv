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
    Eval,
    Apply,
    Halt,
    Error
  } state_t;

  // Error codes
  localparam logic [15:0] STATE_ERROR = 16'h6666;
  localparam logic [15:0] FETCH_ERROR = 16'hAAAA;
  localparam logic [15:0] APPY_ERROR  = 16'hBBBB;

  //────────────────────────────────────────────────────────────
  // Registers
  //────────────────────────────────────────────────────────────
  typedef struct {
    logic [15:0] current;
    logic [15:0] next;
  } reg_t;
  reg_t expr, val, error;

  //────────────────────────────────────────────────────────────
  // Memory
  //────────────────────────────────────────────────────────────
  logic        mem_req;
  address_t    mem_addr;
  logic [15:0] mem_data;
  logic        mem_ready;
  memory mem (
    .clk(clk),
    .rst(rst),
    .req(mem_req),
    .addr_in(mem_addr),
    .data_ready(mem_ready),
    .data_out(mem_data)
  );

  //────────────────────────────────────────────────────────────
  // Seven-segment display
  //────────────────────────────────────────────────────────────
  seven_segment ssg (
    .clk(clk),
    .hex(val.current),
    .cathodes(cathodes),
    .anodes(anodes)
  );

  //────────────────────────────────────────────────────────────
  // Combinational FSM Logic
  //────────────────────────────────────────────────────────────
  struct {
    state_t current = SelectExpr;
    state_t next;
  } state;

  logic go_pressed, go_prev;

  always_comb begin
    state.next = state.current;
    expr.next  = expr.current;
    val.next   = val.current;
    error.next = error.current;

    leds = 16'b0000;

    case (state.current)

      SelectExpr: begin
        val.next = switches;
        if (go_pressed) begin
          val.next = lisp_defs::LISP_NIL;
          expr.next = switches;
          state.next = Fetch;
        end else begin
          state.next = SelectExpr;
        end
      end

      // Retrieves the next expression from memory
      Fetch: begin
        val.next = expr.current;
        state.next = Halt;
      end

      // Determines what kind of thing the expr is, and what to do with it
      Eval: begin
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
      state.current <= SelectExpr;
      expr.current  <= lisp_defs::LISP_NIL;
      expr.next     <= lisp_defs::LISP_NIL;
      val.current   <= lisp_defs::LISP_NIL;
      val.next      <= lisp_defs::LISP_NIL;
      error.current <= lisp_defs::LISP_NIL;
      error.next    <= lisp_defs::LISP_NIL;
    end else begin
      state.current <= state.next;
      expr.current  <= expr.next;
      val.current   <= val.next;
      error.current <= error.next;
    end
  end

  // For latching the expr user input
  always_ff @(posedge clk) begin
    go_prev    <= btn_start;
    go_pressed <= btn_start & ~go_prev; // Edge detection
  end

endmodule
