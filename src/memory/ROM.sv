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
    rom['h0] = lisp::TYPE_NUMBER;
    rom['h1] = 8'h05;
    rom['h2] = lisp::TYPE_NUMBER;
    rom['h3] = 8'h03;
    // + primitive
    rom['h4] = lisp::TYPE_FUNC_PRIM;
    rom['h5] = lisp::TYPE_PRIM_ADD;
    rom['h6] = lisp::NIL;
    rom['h7] = lisp::NIL;

    // expr: (+ 5 3) = (+ (5 (3 NIL)))
    // (CONS 3 NIL)
    rom['h8] = lisp::TYPE_CONS;
    rom['h9] = 8'h3;
    rom['hA] = lisp::NIL;

    // (CONS 5 (CONS 3 NIL))
    rom['hB] = lisp::TYPE_CONS;
    rom['hC] = 8'h1;
    rom['hD] = 8'h8;

    // (CONS + (CONS 5 (CONS 3 NIL)))
    rom['hE]  = lisp::TYPE_CONS;
    rom['hF]  = 8'h4;
    rom['h10] = 8'hB;

    // Expr = 8'hE
  end

  always_ff @(posedge clk) begin
    data_out <= rom[addr];
  end
endmodule
