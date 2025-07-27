`timescale 1ns / 1ps

`include "../src/lisp.sv"

module core_sim();
  logic clk = 0;
  logic rst = 0;
  logic btn_start = 0;
  logic [15:0] switches;
  logic [7:0]  cathodes;
  logic [3:0]  anodes;
  logic [15:0] leds;

  localparam int MemorySize = 1024;

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

  task clear_memory(input logic [lisp::word_size:0] mem[MemorySize]);
    begin
      for (int i = 0; i < MemorySize; i++) begin
        mem[i] = 16'h0000;
        d0.mem.memory[i] = 16'h0000;
      end
    end
  endtask

  // Wait until system finishes execution
  task wait_until_done;
    while (d0.state.current !== lisp::Halt && d0.state.current !== lisp::Error) begin
      @(posedge clk);
    end
    // Three more cycles to let everything settle down
    for (int i = 0; i < 3; i++) begin
      @(posedge clk);
    end
  endtask

  // Main test function
  task run_expr_via_button(
    input logic [lisp::word_size:0] expr_value,
    input logic [lisp::word_size:0] mem_values[MemorySize],
    input logic [lisp::word_size:0] expected_val
  );
    begin
      // ───── Set switches to desired expr ───────
      switches = expr_value;
      btn_start = 0;

      // ───── Reset core and memory ───────────────
      rst = 1;
      for (int i = 0; i < 3; i++) @(posedge clk);
      // @(posedge clk);
      rst = 0;
      @(posedge clk);

      // ───── Set memory contents ───────────────
      for (int i = 0; i < MemorySize; i++) begin
        d0.mem.memory[i] = mem_values[i];
      end

      // ───── Pulse button to trigger start ──────
      btn_start = 1;
      @(posedge clk);
      btn_start = 0;
      @(posedge clk);

      // ───── Wait for completion ────────────────
      wait_until_done();

      // ───── Validate results ───────────────────
      if (d0.state.current == lisp::Error) begin
        $fatal(1, "Execution failed: error = %h", d0.error_code_reg);
      end else if (d0.val.current !== expected_val) begin
        $fatal(1, "Assertion failed: val = %h (expected %h)", d0.val.current, expected_val);
      end else begin
        $display("PASS: val = %h", d0.val.current);
      end
    end
  endtask

  initial begin
    logic [lisp::word_size:0] memory[MemorySize];
    clear_memory(memory);
    memory['h0] = { 1'b0, lisp::TYPE_NUMBER };
    memory['h1] = { 16'h2A2A };
    run_expr_via_button(16'h0001, memory, 16'h2A2A);

    $display("✅ All tests passed!");
    $finish;
  end

endmodule
