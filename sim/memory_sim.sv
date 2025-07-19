`timescale 1ns / 1ps

`include "../src/lisp_defs.sv"

module memory_sim();
  logic clk = 0;
  logic rst = 0;

  logic req;
  logic [15:0] addr_in;
  logic data_ready;
  logic [15:0] data_out;

  logic         write_enable;
  logic  [14:0] data_type;
  logic  [15:0] car_data;
  logic  [15:0] cdr_data;
  logic         write_done;
  logic  [15:0] ptr;

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
    .write_enable(write_enable),
    .data_type(data_type),
    .car_data(car_data),
    .cdr_data(cdr_data),
    .write_done(write_done),
    .ptr(ptr)
  );

  // Used for testing. Saves the output pointers
  logic [15:0] ptr_array[100];

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

  task write_mem(
    input  logic [14:0] type_val,
    input  logic [15:0] car_val,
    input  logic [15:0] cdr_val,
    output logic [15:0] ptr_out
  );
    begin
      data_type    = type_val;
      car_data     = car_val;
      cdr_data     = cdr_val;
      write_enable = 1'b1;
      @(posedge clk);
      write_enable = 1'b0;

      wait(write_done);
      @(posedge clk);

      ptr_out = ptr;
      $display("Cell written: @%h, header=%h, car=%h, cdr=%h", ptr_out, type_val, car_val, cdr_val);
    end
  endtask

  // Task to perform a read request and check output
  task read_mem(input logic [15:0] address, input logic [15:0] expected_data);
    begin
      addr_in = address;
      req = 1;
      @(posedge clk);
      if (data_ready !== 1) $fatal(1, "data_ready not asserted on read");
      if (data_out !== expected_data) $fatal(1, "Read data mismatch at addr %h: got %h, expected %h", address, data_out, expected_data);
      else $display("Read at addr %h successful: data=%h", address, data_out);
      req = 0;
      @(posedge clk);
    end
  endtask

  initial begin
    // Start with reset
    clear_memory();
    do_reset();

    write_mem(lisp_defs::TYPE_NUMBER, 16'hDEAD, lisp_defs::LISP_NIL, ptr_array[0]);
    write_mem(lisp_defs::TYPE_NUMBER, 16'hBEEF, lisp_defs::LISP_NIL, ptr_array[1]);

    // we need to do a -1 here to read the actual data, since we have no eval
    // stage, and we are just reading raw memory.
    read_mem(ptr_array[0] - 1, 16'hDEAD);
    read_mem(ptr_array[1] - 1, 16'hBEEF);

    $display("✅ All memory_sim tests completed successfully.");
    $finish;
  end

endmodule
