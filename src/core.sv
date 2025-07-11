`timescale 1ns / 1ps
`default_nettype none

module core (
    input  wire         CLK,
    // input  wire  [15:0] SWITCHES,
    output logic [ 7:0] CATHODES,
    output logic [ 3:0] ANODES,
    output logic [15:0] LEDS
);
  typedef enum logic [2:0] {
    TYPE_NUMBER  = 3'b000
  } tag_t;

  typedef enum logic [3:0] {
    FETCH,
    EVAL_CONST,
    HALT,
    ERROR
  } state_t;

  // Eval registers
  logic [15:0] EXP;
  logic [15:0] VAL;

  // Logic registers
  logic [11:0] ADDR_REQ;
  logic [15:0] MEM_DATA;

  // State registers
  state_t STATE;

  initial begin
    EXP = 16'h0001; // [0][NUMBER][INDEX = 1]
    STATE = FETCH;
  end

  memory mem (
      .CLK(CLK),
      .ADDR_IN(ADDR_REQ),
      .DATA_OUT(MEM_DATA)
  );

  seven_segment ssg (
      .CLK(CLK),
      .HEX(VAL),
      .CATHODES(CATHODES),
      .ANODES(ANODES)
  );

  always_ff @(posedge CLK) begin
      case (STATE)
          FETCH: begin
              case (EXP[14:12])
                  TYPE_NUMBER: begin
                      ADDR_REQ  <= EXP[11:0];
                      STATE <= EVAL_CONST;
                  end
                  default: STATE <= ERROR;
              endcase
          end
          EVAL_CONST: begin
              VAL <= MEM_DATA;
              STATE <= HALT;
          end
          HALT: LEDS <= {{15{1'b0}}, 1'b1};
          ERROR: LEDS <= 16'hAAAA;   // 10101010... Easy to see on the leds.
          default: LEDS <= 16'h6666; // 01100110... Bad code fallback
      endcase
  end

endmodule
