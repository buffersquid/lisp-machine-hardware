`timescale 1ns / 1ps
`default_nettype none

module core (
    input wire CLK,
    input wire [15:0] SWITCHES,
    output logic [7:0] CATHODES,
    output logic [3:0] ANODES
);

  seven_segment ssg (
      .CLK(CLK),
      .HEX(SWITCHES),
      .CATHODES(CATHODES),
      .ANODES(ANODES)
  );

endmodule
