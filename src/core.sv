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
    TYPE_NUMBER  = 3'b000
  } tag_t;

  typedef enum logic [3:0] {
    Fetch,
    MemWait,
    EvalConst,
    Halt,
    Error
  } state_t;

  typedef struct packed {
    logic     active;
    address_t address;
    state_t   continue_state;
  } memory_request_t;

  //────────────────────────────────────────────────────────────
  // Registers
  //────────────────────────────────────────────────────────────
  logic [15:0] expr, expr_next = 16'h0001;
  logic [15:0] val,  val_next  = 16'h0000;

  //────────────────────────────────────────────────────────────
  // Memory
  //────────────────────────────────────────────────────────────
  logic [15:0] mem_data;
  logic        mem_ready;
  memory mem (
    .clk(CLK),
    .req(memory_request.active),
    .addr_in(memory_request.address),
    .data_ready(mem_ready),
    .data_out(mem_data)
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
  state_t state, state_next, after_read  = Fetch;
  memory_request_t memory_request;
  always_comb begin
    // Default memory request (inactive)
    memory_request.active = 1'b0;
    memory_request.address = '0;
    memory_request.continue_state = state;

    state_next = state; // default, stay in the same state
    expr_next = expr;
    val_next = val;

    LEDS = 16'b0000;

    case (state)

      Fetch: begin
        case (expr[14:12])
          TYPE_NUMBER: begin
            memory_request.active = 1'b1;
            memory_request.address = expr[11:0];
            memory_request.continue_state = EvalConst;
            state_next = MemWait;
          end
          default: state_next = Error;
        endcase
      end

      MemWait: begin
        if (mem_ready) state_next = after_read;
      end

      EvalConst: begin
        val_next = mem_data;
        state_next = Halt;
      end

      Halt: LEDS = {{15{1'b0}}, 1'b1};
      Error: LEDS = 16'hAAAA;   // 10101010... Easy to see on the leds.
      default: LEDS = 16'h6666; // 01100110... Bad code fallback
    endcase
  end

  //────────────────────────────────────────────────────────────
  // Clocked State & Continuation Update
  //────────────────────────────────────────────────────────────
  always_ff @(posedge CLK) begin
    if (memory_request.active) begin
      after_read <= memory_request.continue_state;
    end
    state <= state_next;
    expr  <= expr_next;
    val   <= val_next;
  end

endmodule
