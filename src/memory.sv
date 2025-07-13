`timescale 1ns / 1ps
`default_nettype none

module memory (
  input  wire         clk,
  // ─── Read Interface ──────────────────────────────────────────────
  input  wire         req,
  input  wire  [11:0] addr_in,
  output logic        data_ready,
  output logic [15:0] data_out,
  // ─── Write Interface ─────────────────────────────────────────────
  input  wire         write_enable,
  input  wire  [15:0] write_data,
  output logic [11:0] write_result_addr
);
  localparam int MemorySize = 256;
  // For now, HEAP_START needs to be max memory index + 1. Manually edit.
  localparam int HEAP_START = 5; // NIL. Can be pushed forward later if need be. Basically ROM.

  (* ram_style = "block" *)
  logic [15:0] memory[MemorySize];

  logic [11:0] heap_ptr = HEAP_START;

  initial begin
    memory[0] = {{16{1'b0}}};
    memory[1] = 16'hBEEF;
    memory[2] = 16'hDEAD;
    memory[3] = 16'h0001; // CDR pointer to BEEF
    memory[4] = 16'h0002; // CAR pointer to DEAD
  end

  // ─── Read FSM ────────────────────────────────────────────────────
  always_ff @(posedge clk) begin
    if (req) begin
      data_out   <= memory[addr_in];
      data_ready <= 1'b1;
    end else begin
      data_ready <= 1'b0;
    end
  end

  // ─── Read FSM ────────────────────────────────────────────────────
  always_ff @(posedge clk) begin
    if (write_enable) begin
      memory[heap_ptr]  <= write_data;
      write_result_addr <= heap_ptr;
      heap_ptr          <= heap_ptr + 1;
    end
  end

endmodule
