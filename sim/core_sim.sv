`timescale 1ns / 1ps

`include "../src/lisp_defs.sv"
import lisp_defs::*;

module core_sim();
  logic clk = 0;
  logic rst = 0;
  logic btn_start = 0;
  logic [15:0] switches;
  logic [7:0]  cathodes;
  logic [3:0]  anodes;
  logic [15:0] leds;

  localparam int MemorySize = 256;

  core d0 (
    .clk(clk),
    .rst(rst),
    .btn_start(btn_start),
    .switches(switches),
    .cathodes(cathodes),
    .anodes(anodes),
    .leds(leds)
  );

  always #10 clk = ~clk;

  task clear_memory(input logic [15:0] mem[MemorySize]);
    begin
      for (int i = 0; i < MemorySize; i++) mem[i] = 16'h0000;
    end
  endtask

  // Wait until system finishes execution
  task wait_until_done;
    while (d0.state !== Halt && d0.state !== Error) begin
      @(posedge clk);
    end
  endtask

  // Main test function
  task run_expr_via_button(
    input logic [15:0] expr_value,
    input logic [15:0] mem_values[MemorySize],
    input logic [15:0] expected_val
  );
    begin
      // ───── Reset core and memory ───────────────
      rst = 1;
      @(posedge clk);
      rst = 0;
      @(posedge clk);

      // ───── Set memory contents ───────────────
      for (int i = 0; i < MemorySize; i++) begin
        d0.mem.memory[i] = mem_values[i];
      end

      // ───── Set switches to desired expr ───────
      switches = expr_value;
      btn_start = 0;
      @(posedge clk);
      @(posedge clk);

      // ───── Pulse button to trigger start ──────
      btn_start = 1;
      @(posedge clk);
      btn_start = 0;
      @(posedge clk);

      // ───── Wait for completion ────────────────
      wait_until_done();

      // ───── Validate results ───────────────────
      if (d0.state == Error) begin
        $fatal(1, "Execution failed: error = %h", d0.error);
      end else if (d0.val !== expected_val) begin
        $fatal(1, "Assertion failed: val = %h (expected %h)", d0.val, expected_val);
      end else begin
        $display("PASS: val = %h", d0.val);
      end
    end
  endtask

  initial begin
    logic [15:0] mem[MemorySize];

    // Test 1: Evaluate number at memory[1] = 0xDEAD
    clear_memory(mem);
    mem[1] = 16'hDEAD;
    run_expr_via_button(
      {1'b0, TYPE_NUMBER, 12'h001},
      mem,
      16'hDEAD
    );

    // Test 2: Evaluate (cons DEAD BEEF) pointer at addr 4
    clear_memory(mem);
    mem[1] = 16'hBEEF;
    mem[2] = 16'hDEAD;
    mem[3] = 16'h0001; // cdr = 1
    mem[4] = 16'h0002; // car = 2
    run_expr_via_button(
      {1'b0, TYPE_CONS, 12'h004},
      mem,
      {1'b0, TYPE_CONS, 12'h004}
    );

    $display("✅ All tests passed!");
    $finish;
  end

endmodule
