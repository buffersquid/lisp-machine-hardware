module top (
  input  wire         CLK100MHZ,
  input  wire  [ 4:0] BTN,
  input  wire  [15:0] SWITCHES,
  output logic [15:0] LEDS,
  output logic [ 7:0] CATHODES,
  output logic [ 3:0] ANODES
);

  core my_core (
    .clk(CLK100MHZ),
    .btn_start(BTN[0]),
    .switches(SWITCHES),
    .leds(LEDS),
    .cathodes(CATHODES),
    .anodes(ANODES)
  );

endmodule
