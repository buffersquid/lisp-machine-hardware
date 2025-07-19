`timescale 1ns / 1ps

`include "../src/lisp_defs.sv"

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
      mem[0] = lisp_defs::LISP_NIL;
      for (int i = 1; i < d0.mem.MemorySize; i++) mem[i] = 16'h0000;
    end
  endtask

  // Wait until system finishes execution
  task wait_until_done;
    while (d0.state.current !== d0.Halt && d0.state.current !== d0.Error) begin
      @(posedge clk);
    end
    // Three more cycles to let everything settle down
    for (int i = 0; i < 3; i++) begin
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
      // ───── Set switches to desired expr ───────
      switches = expr_value;
      btn_start = 0;

      // ───── Reset core and memory ───────────────
      rst = 1;
      @(posedge clk);
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
      if (d0.state.current == d0.Error) begin
        $fatal(1, "Execution failed: error = %h", d0.error);
      end else if (d0.val.current !== expected_val) begin
        $fatal(1, "Assertion failed: val = %h (expected %h)", d0.val.current, expected_val);
      end else begin
        $display("PASS: val = %h", d0.val.current);
      end
    end
  endtask

  initial begin
    logic [15:0] mem[MemorySize];

    clear_memory(mem);
    mem[0] = lisp_defs::LISP_NIL;
    mem[1] = lisp_defs::LISP_NIL;
    mem[2] = 16'hDEAD;
    mem[3] = { 1'b0, lisp_defs::TYPE_NUMBER };
    run_expr_via_button(
      15'h0003,
      mem,
      16'hDEAD 
    );

    $display("✅ All tests passed!");
    $finish;
  end

endmodule
