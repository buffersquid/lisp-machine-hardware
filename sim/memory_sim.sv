`timescale 1ns / 1ps

`include "../src/lisp_defs.sv"

module memory_sim();
  logic clk = 0;
  logic rst = 0;

  logic        read_enable;
  logic [15:0] addr_in;
  logic [14:0] header_out;
  logic [15:0] car_out, cdr_out;

  logic         write_enable;
  logic  [14:0] data_type;
  logic  [15:0] car_data;
  logic  [15:0] cdr_data;
  logic  [15:0] ptr;

  logic         done;

  // Instantiate the memory module
  memory #(
    .HeapStart(1)
  ) m0 (
    .clk(clk),
    .rst(rst),
    // --- Read ---
    .read_enable(read_enable),
    .addr_in(addr_in),
    .header_out(header_out),
    .car_out(car_out),
    .cdr_out(cdr_out),
    // --- Write ---
    .write_enable(write_enable),
    .data_type(data_type),
    .car_data(car_data),
    .cdr_data(cdr_data),
    .ptr(ptr),
    // --- General ---
    .done(done)
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

      wait(done);
      @(posedge clk);

      ptr_out = ptr;
      $display("Cell written: @%h, header=%h, car=%h, cdr=%h", ptr_out, type_val, car_val, cdr_val);
    end
  endtask

  // Task to perform a read request and check output
  task read_mem(
    input logic [15:0] address,
    input logic [14:0] expected_header,
    input logic [15:0] expected_car, expected_cdr
  );
    begin
      addr_in = address;
      read_enable = 1;
      @(posedge clk);
      read_enable = 0;
      wait(done);
      if (done !== 1) $fatal(1, "done not asserted");
      else if (header_out !== expected_header) $fatal(1, "Read data mismatch at header %h: got %h, expected %h", address, header_out, expected_header);
      else if (car_out !== expected_car) $fatal(1, "Read data mismatch at car %h: got %h, expected %h", address, car_out, expected_car);
      else if (cdr_out !== expected_cdr) $fatal(1, "Read data mismatch at cdr %h: got %h, expected %h", address, cdr_out, expected_cdr);
      else $display("Read at addr %h successful", address);
      @(posedge clk);
    end
  endtask

  initial begin
    // Start with reset
    clear_memory();
    do_reset();

    write_mem(lisp_defs::TYPE_NUMBER, 16'hDEAD, lisp_defs::LISP_NIL, ptr_array[0]);
    write_mem(lisp_defs::TYPE_NUMBER, 16'hBEEF, lisp_defs::LISP_NIL, ptr_array[1]);

    read_mem(ptr_array[0], lisp_defs::TYPE_NUMBER, 16'hDEAD, lisp_defs::LISP_NIL);
    read_mem(ptr_array[1], lisp_defs::TYPE_NUMBER, 16'hBEEF, lisp_defs::LISP_NIL);

    $display("✅ All memory_sim tests completed successfully.");
    $finish;
  end

endmodule
