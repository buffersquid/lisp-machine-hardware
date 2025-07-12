`timescale 1ns / 1ps
`default_nettype none

module core (
  input  wire         CLK,
  output logic [ 7:0] CATHODES,
  output logic [ 3:0] ANODES,
  output logic [15:0] LEDS
);
  typedef enum logic [2:0] {
    TYPE_NUMBER  = 3'b000
  } tag_t;

  typedef enum logic [3:0] {
    Fetch,
    EvalConst,
    Halt,
    Error
  } state_t;

  // Eval registers
  logic [15:0] expr;
  logic [15:0] val;

  // Logic registers
  logic [11:0] addr_req;
  logic [15:0] mem_data;
  logic        mem_req;
  logic        mem_ready;

  // State registers
  state_t state, next_state;

  initial begin
    expr = 16'h0001; // [0][number_t][INDEX = 1]
    state = Fetch;
  end

  memory mem (
    .clk(CLK),
    .req(mem_req),
    .addr_in(addr_req),
    .data_ready(mem_ready),
    .data_out(mem_data)
  );

  seven_segment ssg (
    .clk(CLK),
    .hex(val),
    .cathodes(CATHODES),
    .anodes(ANODES)
  );

  always_comb begin
    next_state = state; // default, stay in the same state
    LEDS = 16'b0000;
    mem_req = 1'b0; // By default, we don't request memory
    case (state)
      Fetch: begin
        case (expr[14:12])
          TYPE_NUMBER: begin
            addr_req   = expr[11:0];
            mem_req    = 1'b1;
            next_state = EvalConst;
          end
          default: next_state = Error;
        endcase
      end
      EvalConst: begin
        if (mem_ready) begin
          val = mem_data;
          next_state = Halt;
        end
      end
      Halt: LEDS = {{15{1'b0}}, 1'b1};
      Error: LEDS = 16'hAAAA;   // 10101010... Easy to see on the leds.
      default: LEDS = 16'h6666; // 01100110... Bad code fallback
    endcase
  end

  always_ff @(posedge CLK) begin
    state <= next_state;
  end

endmodule
