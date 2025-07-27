`timescale 1ns / 1ps
`default_nettype none

`include "lisp.sv"

module memory #(
  parameter MemSize = 1024
)(
  input  wire  clk,
  input  wire  [lisp::word_size:0] addr_in,
  output logic [lisp::word_size:0] data_out
);
  (* ram_style = "block" *)
  logic [lisp::word_size:0] memory[MemSize];

  initial begin
    memory['h0] = { 1'b0, lisp::TYPE_NUMBER };
    memory['h1] = { 15'h2A2A };
  end

  always_ff @(posedge clk) begin
    data_out <= memory[addr_in];
  end
endmodule
