`timescale 1ns/1ps
`default_nettype none

module seven_segment (
  input  wire         CLK,       // 100 MHz system clock
  input  wire  [15:0] HEX,       // four 4‑bit digits
  output logic [ 7:0] CATHODES,  
  output logic [ 3:0] ANODES
);

  //─────────────────────────────────────────────────────
  // parameters & lookups
  //─────────────────────────────────────────────────────
  localparam int CLK_FREQ     = 100_000_000;
  localparam int REFRESH_HZ   = 500;
  localparam int CNT_MAX      = CLK_FREQ/REFRESH_HZ/2;

  typedef enum logic [1:0] { DIG0, DIG1, DIG2, DIG3 } digit_t;

  // 0‑F → segment patterns
  localparam logic [7:0] SEGMENT_LOOKUP [0:15] = '{
    8'h81, 8'hCF, 8'h92, 8'h86,
    8'hCC, 8'hA4, 8'hA0, 8'h8F,
    8'h80, 8'h8C, 8'h88, 8'hE0,
    8'hB1, 8'hC2, 8'hB0, 8'hB8
  };

  // which anode to drive active (low)
  localparam logic [3:0] ANODE_LOOKUP [0:3] = '{4'b1110,4'b1101,4'b1011,4'b0111};

  //─────────────────────────────────────────────────────
  // clock divider → 500 Hz refresh clock
  //─────────────────────────────────────────────────────
  logic                slow_clk    = 1'b0;
  logic [31:0]         div_counter = 0;
  always_ff @(posedge CLK) begin
    if (div_counter == CNT_MAX-1) begin
      div_counter <= 0;
      slow_clk    <= ~slow_clk;
    end else begin
      div_counter <= div_counter + 1;
    end
  end

  //─────────────────────────────────────────────────────
  // digit‐scan & lookup
  //─────────────────────────────────────────────────────
  digit_t current_digit = DIG0;
  always_ff @(posedge slow_clk) begin
    // rotate through DIG0→DIG1→DIG2→DIG3→DIG0
    case (current_digit)
      DIG0: current_digit <= DIG1;
      DIG1: current_digit <= DIG2;
      DIG2: current_digit <= DIG3;
      DIG3: current_digit <= DIG0;
      default: current_digit <= DIG0;
    endcase

    // update anodes and cathodes from lookup tables
    ANODES    <= ANODE_LOOKUP[current_digit];
    CATHODES <= SEGMENT_LOOKUP[ HEX[4*current_digit +: 4] ];
  end

endmodule
