`timescale 1ns / 1ps
`default_nettype none

module core (
  input  wire         CLK,
  output logic [ 7:0] CATHODES,
  output logic [ 3:0] ANODES,
  output logic [15:0] LEDS
);

  //────────────────────────────────────────────────────────────
  // Types
  //────────────────────────────────────────────────────────────
  typedef logic [11:0] address_t;

  typedef enum logic [2:0] {
    TYPE_NUMBER,
    TYPE_CONS
  } tag_t;

  typedef enum logic [3:0] {
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

  // Debugging errors
  typedef enum logic [15:0] {
    STATE_ERROR = 16'h6666,
    FETCH_ERROR = 16'hAAAA
  } error_t;

  //────────────────────────────────────────────────────────────
  // Registers
  //────────────────────────────────────────────────────────────
  logic [15:0] expr = {1'b0, TYPE_CONS, 12'h004};
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
  logic [15:0] write_data;
  logic        write_enable;
  logic [11:0] write_result_addr;
  memory mem (
    .clk(CLK),
    .req(memory_read.active),
    .addr_in(memory_read.address),
    .data_ready(mem_ready),
    .data_out(mem_data),
    .write_enable(write_enable),
    .write_data(write_data),
    .write_result_addr(write_result_addr)
  );

  //────────────────────────────────────────────────────────────
  // Seven-segment display
  //────────────────────────────────────────────────────────────
  seven_segment ssg (
    .clk(CLK),
    .hex(val),
    .cathodes(CATHODES),
    .anodes(ANODES)
  );

  //────────────────────────────────────────────────────────────
  // Combinational FSM Logic
  //────────────────────────────────────────────────────────────
  // state_t state, state_next, after_read = Fetch;
  state_t state = Fetch;
  state_t state_next, after_read;
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

    LEDS = 16'b0000;

    case (state)

      Fetch: begin
        case (expr[14:12])
          TYPE_NUMBER: begin
            memory_read.active = 1'b1;
            memory_read.address = expr[11:0];
            memory_read.continue_state = EvalConst;
            state_next = MemWait;
          end
          TYPE_CONS: begin
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
          TYPE_NUMBER: begin
            val_next = expr;
            state_next = Halt;
          end
        endcase
      end

      Halt: LEDS = {{15{1'b0}}, 1'b1};
      Error: LEDS = error;
      default: LEDS = STATE_ERROR;
    endcase
  end

  //────────────────────────────────────────────────────────────
  // Clocked State & Continuation Update
  //────────────────────────────────────────────────────────────
  always_ff @(posedge CLK) begin
    if (memory_read.active) begin
      after_read <= memory_read.continue_state;
    end
    state <= state_next;
    expr  <= expr_next;
    val   <= val_next;
    error <= error_next;
  end

endmodule
