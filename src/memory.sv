`timescale 1ns / 1ps
`default_nettype none

`include "lisp_defs.sv"

module memory #(
  parameter int HeapStart = 5 // Start of heap cells after ROM/NIL/etc
)(
  input  wire         clk,
  input  wire         rst,
  // ─── Read Interface ──────────────────────────────────────────────
  input  wire         req,
  input  wire  [15:0] addr_in,
  output logic        data_ready,
  output logic [15:0] data_out
);
  // Memory layout parameters
  localparam int MemorySize = 256;

  (* ram_style = "block" *)
  logic [15:0] memory[MemorySize];

  initial begin
    memory[0] = lisp_defs::LISP_NIL;
    // memory dump for integer 0x789A
    // header -> data_0 -> Nil (marks the end of the number)
    // expr = 15'h0002;
    memory[1] = 16'h0004;
    memory[2] = { 1'b0, lisp_defs::TYPE_NUMBER };
    memory[3] = lisp_defs::LISP_NIL;
    memory[4] = 16'h789A;
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      // Reset all stateful signals
      data_ready <= 0;
      data_out   <= 0;
    end else begin
      // --- Read FSM ---
      if (req) begin
        data_out   <= memory[addr_in];
        data_ready <= 1'b1;
      end else begin
        data_ready <= 1'b0;
      end
    end
  end
endmodule
