`timescale 1ns / 1ps

`include "../src/lisp_defs.sv"

module memory_sim();
  logic clk = 0;
  logic rst = 0;

  logic req;
  logic [11:0] addr_in;
  logic data_ready;
  logic [15:0] data_out;

  logic cons_en;
  logic [15:0] cons_car;
  logic [15:0] cons_cdr;
  logic cons_done;
  logic [15:0] cons_ptr;

  // Instantiate the memory module
  memory #(
    .HeapStart(1)
  ) m0 (
    .clk(clk),
    .rst(rst),
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

  // Task to write a cons cell and check done signal
  task write_cons_cell(input logic [15:0] car_val, input logic [15:0] cdr_val);
    begin
      cons_car = car_val;
      cons_cdr = cdr_val;
      cons_en = 1'b1;
      @(posedge clk);
      cons_en = 1'b0;

      // Wait for cons_done to assert
      wait(cons_done == 1);
      @(posedge clk);  // wait one more cycle to latch cons_ptr
      $display("Cons cell written: cons_ptr=%h, car=%h, cdr=%h", cons_ptr, car_val, cdr_val);
    end
  endtask

  // Task to perform a read request and check output
  task read_mem(input logic [11:0] address, input logic [15:0] expected_data);
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

    // Write a few cons cells
    write_cons_cell(16'hDEAD, 16'hBEEF);
    write_cons_cell(16'h1234, 16'h5678);
    write_cons_cell(16'hABCD, 16'hEF01);

    // Read back the initialized memory locations
    read_mem(12'h000, 16'h0000); // LISP_NIL (from initial block)
    read_mem(12'h001, 16'hBEEF);
    read_mem(12'h002, 16'hDEAD);

    // Optionally: reset and test again
    do_reset();

    $display("✅ All memory_sim tests completed successfully.");
    $finish;
  end

endmodule
