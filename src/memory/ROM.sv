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
    rom['h1] = 8'h12;
    rom['h2] = lisp::TYPE_NUMBER;
    rom['h3] = 8'h34;

    // cons primitive
    rom['h4] = lisp::TYPE_FUNC_PRIM;
    rom['h5] = lisp::TYPE_PRIM_CONS;
    rom['h6] = lisp::NIL;
    rom['h7] = lisp::NIL;

    // (cons 12 34) = (cons . (12 . (34 . NIL)))
    // (CONS 34 NIL)
    rom['h8] = lisp::TYPE_CONS;
    rom['h9] = 'h2;
    rom['hA] = lisp::NIL;

    // (CONS 12 (CONS 34 NIL))
    rom['hB] = lisp::TYPE_CONS;
    rom['hC] = 'h0;
    rom['hD] = 'h8;

    // (CONS cons-primitive (CONS 12 (CONS 34 NIL)))
    rom['hE]  = lisp::TYPE_CONS;
    rom['hF]  = 'h4;
    rom['h10] = 'hB;

    // car primitive
    rom['h11] = lisp::TYPE_FUNC_PRIM;
    rom['h12] = lisp::TYPE_PRIM_CAR;
    rom['h13] = lisp::NIL;
    rom['h14] = lisp::NIL;

    // (CONS (cons 12 34) NIL)
    rom['h15] = lisp::TYPE_CONS;
    rom['h16] = 'hE;
    rom['h17] = lisp::NIL;

    // (CONS car-primitive (CONS (cons 12 34) NIL))
    rom['h18] = lisp::TYPE_CONS;
    rom['h19] = 'h11;
    rom['h1A] = 'h15;
  end

  always_ff @(posedge clk) begin
    data_out <= rom[addr];
  end
endmodule
