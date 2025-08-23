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
    logic [lisp::data_width-1:0] current;
    logic [lisp::data_width-1:0] next;
  } reg_t;
  reg_t expr;
  reg_t val;

  //────────────────────────────────────────────────────────────
  // Memory
  //────────────────────────────────────────────────────────────
  // Control signals
  logic start_fetch, fetch_done;

  logic active_read, boot_done, write_enable;
  logic [lisp::addr_width-1:0] addr_in_latch;
  // Inputs
  logic [lisp::addr_width-1:0] addr_in;
  logic [lisp::data_width-1:0] write_data;
  // Outputs
  logic [lisp::data_width-1:0] read_data;

  memory_controller #(
    .ADDR_WIDTH(lisp::addr_width),
    .DATA_WIDTH(lisp::data_width)
  ) mem (
    .clk(clk),
    .rst(rst),
    .boot_done(boot_done),
    .addr(addr_in_latch),
    .write_enable(write_enable),
    .write_data(write_data),
    .read_data(read_data)
  );

  typedef enum {
    FETCH_IDLE,
    FETCH_TAG_REQ,
    FETCH_TAG_STORE,
    FETCH_VAL_REQ,
    FETCH_VAL_STORE
  } fetch_state_t;

  struct packed {
    fetch_state_t current;
    fetch_state_t next;
  } fetch_state;

  reg_t tag_reg;
  reg_t val_reg;

  always_comb begin
    fetch_state.next = fetch_state.current;
    tag_reg.next     = tag_reg.current;
    val_reg.next     = val_reg.current;

    active_read = 1'b0;
    addr_in     = '0;
    fetch_done  = 1'b0;

    case (fetch_state.current)
      FETCH_IDLE: begin
        if (start_fetch) begin
          addr_in = expr.current;
          active_read = 1'b1;
          fetch_state.next = FETCH_TAG_REQ;
        end
      end

      FETCH_TAG_REQ: fetch_state.next = FETCH_TAG_STORE;
      FETCH_TAG_STORE: begin
        tag_reg.next = read_data;
        case (read_data)
          lisp::TYPE_NUMBER: begin
            addr_in = expr.current + 1;
            active_read = 1'b1;
            fetch_state.next = FETCH_VAL_REQ;
          end
        endcase
      end

      FETCH_VAL_REQ: fetch_state.next = FETCH_VAL_STORE;
      FETCH_VAL_STORE: begin
        val_reg.next = read_data;
        fetch_done = 1'b1;
        fetch_state.next = FETCH_IDLE;
      end
    endcase
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      fetch_state.current <= FETCH_IDLE;
      tag_reg.current     <= 'h0;
      val_reg.current     <= 'h0;
    end else begin
      fetch_state.current <= fetch_state.next;
      tag_reg.current     <= tag_reg.next;
      val_reg.current     <= val_reg.next;

      if (active_read) begin
        addr_in_latch <= addr_in;
      end
    end
  end

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
    expr.next  = expr.current;
    val.next   = val.current;

    start_fetch = 1'b0;

    leds = 16'b0000;
    // Tehnically, this is a STATE ERROR, but it doesn't really matter if we
    // don't get into the error state.
    error_code = 4'h0;

    case (state.current)

      lisp::Boot: begin
        if (boot_done) state.next = lisp::SelectExpr;
      end

      lisp::SelectExpr: begin
        if (go_pressed) begin
          expr.next = switches;
          start_fetch  = 1'b1;
          state.next = lisp::MemWait;
        end else begin
          state.next = lisp::SelectExpr;
        end
      end

      lisp::MemWait: if (fetch_done) state.next = lisp::Eval;

      // Determines what kind of thing the expr is, and what to do with it
      lisp::Eval: begin
        case (tag_reg.current)
          lisp::TYPE_NUMBER: begin
            val.next = val_reg.current;
            state.next = lisp::Halt;
          end
        endcase
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
      state.current <= lisp::Boot;
      val.current   <= lisp::Boot;
      expr.current  <= 'h0;
    end else begin
      state.current <= state.next;
      val.current   <= val.next;
      expr.current  <= expr.next;

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
