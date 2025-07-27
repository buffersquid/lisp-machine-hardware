`timescale 1ns / 1ps

`include "../src/lisp.sv"

module memory_sim();
  logic clk = 0;
  logic [15:0] addr_in;
  logic [15:0] data_out;

  localparam MemorySize = 1024;

  // Instantiate the memory module
  memory #(
    .MemorySize(MemorySize)
  ) m0 (
    .clk(clk),
    .addr_in(addr_in),
    .data_out(data_out)
  );

  // Used for testing. Saves the output pointers
  logic [15:0] ptr_array[100];

  // Clock generation: 50 MHz clock (20 ns period)
  always #10 clk = ~clk;

  task clear_memory(input logic [lisp::word_size:0] mem[MemorySize]);
    begin
      for (int i = 0; i < MemorySize; i++) begin
        mem[i] = 16'h0000;
        m0.memory[i] = 16'h0000;
      end
    end
  endtask

  // Task to perform a read request and check output
  task read_mem(
    input logic [15:0] address,
    input logic [15:0] expected_data
  );
    begin
      addr_in = address;
      @(posedge clk);
      @(posedge clk);
      if (data_out !== expected_data) begin
        $fatal(1, "Read data mismatch at %h: got %h, expected %h", address, data_out, expected_data);
      end else begin
        $display("Read at addr %h successful", address);
      end
    end
  endtask

  initial begin
    logic [lisp::word_size:0] memory[MemorySize];
    clear_memory(memory);
    m0.memory['h0] = { 1'b0, lisp::TYPE_NUMBER };
    m0.memory['h1] = { 16'h2A2A };
    read_mem(16'h0001, 16'h2A2A);

    $display("✅ All memory_sim tests completed successfully.");
    $finish;
  end

endmodule
