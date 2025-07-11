`timescale 1ns / 1ps
`default_nettype none

module memory (
  input  wire         CLK,
  input  wire  [11:0] ADDR_IN,
  output logic [15:0] DATA_OUT
);
  localparam int MEMORY_SIZE = 256;

  (* ram_style = "block" *)
  logic [15:0] MEMORY[MEMORY_SIZE];

  initial begin
    MEMORY[0] = {{16{1'b0}}};
    MEMORY[1] = 16'hBEEF;
  end

  always_ff @(posedge CLK) begin
    DATA_OUT <= MEMORY[ADDR_IN];
  end

endmodule
