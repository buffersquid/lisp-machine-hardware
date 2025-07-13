module top (
  input  wire         CLK100MHZ,
  output logic [15:0] LEDS,
  output logic [ 7:0] CATHODES,
  output logic [ 3:0] ANODES
);

  core my_core (
    .clk(CLK100MHZ),
    .leds(LEDS),
    .cathodes(CATHODES),
    .anodes(ANODES)
  );

endmodule
