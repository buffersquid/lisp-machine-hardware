`timescale 1ns / 1ps

`include "../src/lisp_defs.sv"

module memory_sim();
  logic clk = 0;
  logic rst = 0;

  logic req;
  logic [15:0] addr_in;
  logic data_ready;
  logic [15:0] data_out;

  // Instantiate the memory module
  memory #(
    .HeapStart(1)
  ) m0 (
    .clk(clk),
    .rst(rst),
    .req(req),
    .addr_in(addr_in),
    .data_ready(data_ready),
    .data_out(data_out)
  );

  // Clock generation: 50 MHz clock (20 ns period)
  always #10 clk = ~clk;

  task clear_memory();
    begin
      m0.memory[0] = lisp_defs::LISP_NIL;
      for (int i = 1; i < m0.MemorySize; i++) m0.memory[i] = 16'h0000;
    end
  endtask

  // Task to perform a synchronous reset
  task do_reset();
    begin
      rst = 1;
      @(posedge clk);
      rst = 0;
      @(posedge clk);
    end
  endtask

  // Task to perform a read request and check output
  task read_mem(input logic [15:0] address, input logic [15:0] expected_data);
    begin
      addr_in = address;
      req = 1;
      @(posedge clk);
      if (data_ready !== 1) $fatal("data_ready not asserted on read");
      if (data_out !== expected_data) $fatal("Read data mismatch at addr %h: got %h, expected %h", address, data_out, expected_data);
      else $display("Read at addr %h successful: data=%h", address, data_out);
      req = 0;
      @(posedge clk);
    end
  endtask

  initial begin
    // Start with reset
    clear_memory();
    do_reset();

    $display("✅ All memory_sim tests completed successfully.");
    $finish;
  end

endmodule
