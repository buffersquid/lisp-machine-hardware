`timescale 1ns / 1ps
`default_nettype none

module memory (
  input  wire         clk,
  input  wire         req,        // pull high for one clock cycle to request memory
  input  wire  [11:0] addr_in,
  output logic        data_ready,
  output logic [15:0] data_out
);
  localparam int MemorySize = 256;

  (* ram_style = "block" *)
  logic [15:0] memory[MemorySize];

  initial begin
    memory[0] = {{16{1'b0}}};
    memory[1] = 16'hBEEF;
  end

  always_ff @(posedge clk) begin
    if (req) begin
      data_out   <= memory[addr_in];
      data_ready <= 1'b1;
    end else begin
      data_ready <= 1'b0;
    end
  end

endmodule
