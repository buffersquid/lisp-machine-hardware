`timescale 1ns / 1ps

module memory_sim();
  logic        clk;
  logic        req;
  logic [11:0] addr_in;
  logic        data_ready;
  logic [15:0] data_out;
  logic        write_enable;
  logic [15:0] write_data;
  logic [11:0] write_result_addr;

  memory m0 (
    .clk(clk),
    .req(req),
    .addr_in(addr_in),
    .data_ready(data_ready),
    .data_out(data_out),
    .write_enable(write_enable),
    .write_data(write_data),
    .write_result_addr(write_result_addr)
  );

  always begin
    clk = 1; #10;
    clk = 0; #10;
  end

  initial begin
    write_data = 16'hBEEF;
    write_enable = 1;
    #20;
    write_data = 16'hDEAD;
    #20;
    write_data = 16'hDEF0;
    #20;
    write_enable = 0;
    #20;
    req = 1;
    addr_in = 12'h001;
    #20;
    req = 0;
    #20;
    req = 1;
    addr_in = 12'h002;
    #20;
    req = 0;
    #20;
    req = 1;
    addr_in = 12'h003;
    #20;
    req = 0;
  end

endmodule
