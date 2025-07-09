`timescale 1ns / 1ps

module core (
    input CLK,
    input wire [15:0] SWITCHES,
    output wire [15:0] LEDS
);

  assign LEDS = SWITCHES;

endmodule
