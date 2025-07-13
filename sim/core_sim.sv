`timescale 1ns / 1ps

module core_sim();
  logic clk;
  logic [ 7:0] cathodes;
  logic [ 3:0] anodes;
  logic [15:0] leds;

  core c0 (.CLK(clk), .CATHODES(cathodes), .ANODES(anodes), .LEDS(leds));

  always begin
    clk = 1; #10;
    clk = 0; #10;
  end

  initial begin
  end

endmodule
