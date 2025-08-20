`timescale 1ns / 1ps
`default_nettype none

`include "../lisp.sv"

module ROM #(
  parameter ADDR_WIDTH,
  parameter DATA_WIDTH
)(
  input  wire  clk,
  input  wire  [ADDR_WIDTH-1:0] addr,
  output logic [DATA_WIDTH-1:0] data_out
);
  (* rom_style = "block" *)
  reg [DATA_WIDTH-1:0] rom [0:(1 << ADDR_WIDTH)-1];

  initial begin
    rom['h0] = { 1'b0, lisp::TYPE_NUMBER };
    rom['h1] = { 16'h2A2A };
  end

  always_ff @(posedge clk) begin
    data_out <= rom[addr];
  end
endmodule
