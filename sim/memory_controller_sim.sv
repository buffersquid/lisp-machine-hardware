`timescale 1ns / 1ps

`include "../src/lisp.sv"

module memory_controller_sim();
  localparam addrWidth = 6;
  localparam dataWidth = 8;

  logic clk = 0;
  logic rst;
  logic boot_done;
  logic write_enable;
  logic [addrWidth-1:0] addr;
  logic [dataWidth-1:0] write_data;
  logic [dataWidth-1:0] read_data;

  // Instantiate the memory module
  memory_controller #(
    .ADDR_WIDTH(addrWidth), // 2^6 = 64
    .DATA_WIDTH(dataWidth)
  ) m0 (
    .clk(clk),
    .rst(rst),
    .boot_done(boot_done),
    .write_enable(write_enable),
    .addr(addr),
    .write_data(write_data),
    .read_data(read_data)
  );

  // Clock generation: 50 MHz clock (20 ns period)
  always #10 clk = ~clk;

  // Task to perform a read request and check output
  task read_mem(
    input logic [addrWidth-1:0] address,
    input logic [dataWidth-1:0] expected_data
  );
    begin
      @(posedge clk)
      rst = 1;
      @(posedge clk)
      rst = 0;
      @(posedge clk)
      wait(boot_done);
      addr = address;
      @(posedge clk);
      @(posedge clk);
      if (read_data !== expected_data) begin
        $fatal(1, "Read data mismatch at %h: got %h, expected %h", address, read_data, expected_data);
      end else begin
        $display("Read at addr %h successful", address);
      end
    end
  endtask

  initial begin
    read_mem(8'h01, 8'h2A);

    $display("✅ All memory_sim tests completed successfully.");
    $finish;
  end

endmodule
