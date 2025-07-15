`timescale 1ns / 1ps

module memory_sim();
  logic        clk = 0;
  logic        req;
  logic [11:0] addr_in;
  logic        data_ready;
  logic [15:0] data_out;

  logic        cons_en;
  logic [15:0] cons_car;
  logic [15:0] cons_cdr;
  logic        cons_done;
  logic [15:0] cons_ptr;

  memory m0 (
    .clk(clk),
    .req(req),
    .addr_in(addr_in),
    .data_ready(data_ready),
    .data_out(data_out),
    .cons_en(cons_en),
    .cons_car(cons_car),
    .cons_cdr(cons_cdr),
    .cons_done(cons_done),
    .cons_ptr(cons_ptr)
  );

  always #10 clk = ~clk;

  initial begin
    cons_car = 16'hDEAD;
    cons_cdr = 16'hBEEF;
    cons_en  = 1'b1;
    #20;
    cons_en = 1'b0;
    #20;
    cons_car = 16'h1234;
    cons_cdr = 16'h5678;
    cons_en  = 1'b1;
    #20;
    cons_en = 1'b0;
    #20;
    cons_car = 16'hABCD;
    cons_cdr = 16'hEF01;
    cons_en  = 1'b1;
    #20;
    cons_en = 1'b0;
  end

endmodule
