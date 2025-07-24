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
      mem[0] = lisp_defs::NIL;
      for (int i = 1; i < d0.mem.MemorySize; i++) mem[i] = 16'h0000;
    end
  endtask

  // Wait until system finishes execution
  task wait_until_done;
    while (d0.state.current !== lisp_defs::Halt && d0.state.current !== lisp_defs::Error) begin
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
      if (d0.state.current == lisp_defs::Error) begin
        $fatal(1, "Execution failed: error = %h", d0.error_code_reg);
      end else if (d0.val.current !== expected_val) begin
        $fatal(1, "Assertion failed: val = %h (expected %h)", d0.val.current, expected_val);
      end else begin
        $display("PASS: val = %h", d0.val.current);
      end
    end
  endtask

  task test_eval_number();
    logic [15:0] mem[MemorySize];
    clear_memory(mem);
    mem[0] = lisp_defs::NIL;
    mem[1] = lisp_defs::NIL;
    mem[2] = 16'hDEAD;
    mem[3] = { 1'b0, lisp_defs::TYPE_NUMBER };

    run_expr_via_button(15'h0003, mem, 16'hDEAD);
  endtask

  task test_primitive_add();
    logic [15:0] mem[MemorySize];
    clear_memory(mem);

    mem['h0] = lisp_defs::NIL;
    // first number
    mem['h1] = lisp_defs::NIL;
    mem['h2] = 16'h0005;
    mem['h3] = { 1'b0, lisp_defs::TYPE_NUMBER };
    // second number
    mem['h4] = lisp_defs::NIL;
    mem['h5] = 16'h0003;
    mem['h6] = { 1'b0, lisp_defs::TYPE_NUMBER };
    // (3 nil)
    mem['h7] = lisp_defs::NIL;
    mem['h8] = 16'h0006;
    mem['h9] = { 1'b0, lisp_defs::TYPE_CONS };
    // (5 (3 nil))
    mem['hA] = 16'h0009;
    mem['hB] = 16'h0003;
    mem['hC] = { 1'b0, lisp_defs::TYPE_CONS };
    // (+ (5 (3 nil)))
    mem['hD] = 16'h000C;
    mem['hE] = 16'h0012;
    mem['hF] = { 1'b0, lisp_defs::TYPE_CONS };
    // primitive +
    mem['h10] = lisp_defs::NIL;
    mem['h11] = lisp_defs::PRIMOP_ADD;
    mem['h12] = { 1'b0, lisp_defs::TYPE_PRIMITIVE };

    run_expr_via_button(15'h000F, mem, 16'h0008);
  endtask

  task test_primitive_add_many_args();
    logic [15:0] mem[MemorySize];
    clear_memory(mem);

    mem['h0] = lisp_defs::NIL;
    // first number
    mem['h1] = lisp_defs::NIL;
    mem['h2] = 16'h0005;
    mem['h3] = { 1'b0, lisp_defs::TYPE_NUMBER };
    // second number
    mem['h4] = lisp_defs::NIL;
    mem['h5] = 16'h0003;
    mem['h6] = { 1'b0, lisp_defs::TYPE_NUMBER };
    // third number
    mem['h7] = lisp_defs::NIL;
    mem['h8] = 16'h0002;
    mem['h9] = { 1'b0, lisp_defs::TYPE_NUMBER };
    // fourth number
    mem['hA] = lisp_defs::NIL;
    mem['hB] = 16'h0001;
    mem['hC] = { 1'b0, lisp_defs::TYPE_NUMBER };
    // primitive +
    mem['hD] = lisp_defs::NIL;
    mem['hE] = lisp_defs::PRIMOP_ADD;
    mem['hF] = { 1'b0, lisp_defs::TYPE_PRIMITIVE };
    //(5 nil)
    mem['h10] = lisp_defs::NIL;
    mem['h11] = 16'h0003;
    mem['h12] = { 1'b0, lisp_defs::TYPE_CONS };
    //(3 (5 nil))
    mem['h13] = 12'h0012;
    mem['h14] = 16'h0006;
    mem['h15] = { 1'b0, lisp_defs::TYPE_CONS };
    //( 2 (3 (5 nil)))
    mem['h16] = 12'h0015;
    mem['h17] = 16'h0009;
    mem['h18] = { 1'b0, lisp_defs::TYPE_CONS };
    //(1 ( 2 (3 (5 nil))))
    mem['h19] = 12'h0018;
    mem['h1A] = 16'h000C;
    mem['h1B] = { 1'b0, lisp_defs::TYPE_CONS };
    //(+ (1 ( 2 (3 (5 nil)))))
    mem['h1C] = 12'h001B;
    mem['h1D] = 16'h000F;
    mem['h1E] = { 1'b0, lisp_defs::TYPE_CONS };

    run_expr_via_button(15'h001E, mem, 16'h000B);
  endtask

  initial begin
    test_eval_number();
    test_primitive_add();
    test_primitive_add_many_args();

    $display("✅ All tests passed!");
    $finish;
  end

endmodule
