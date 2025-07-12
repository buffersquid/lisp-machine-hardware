`timescale 1ns / 1ps

module core_sim();
  logic CLK;
  logic [ 7:0] CATHODES;
  logic [ 3:0] ANODES;
  logic [15:0] LEDS;
  
  core c0 (.CLK(CLK), .CATHODES(CATHODES), .ANODES(ANODES), .LEDS(LEDS));
  
  always begin
    #10; CLK = 1;
    #10; CLK = 0;
  end
  
  initial begin
  end
    
endmodule
