`timescale 1ns / 1ps
`default_nettype none

`include "lisp_defs.sv"
import lisp_defs::*;

module memory (
  input  wire         clk,
  // ─── Read Interface ──────────────────────────────────────────────
  input  wire         req,
  input  wire  [11:0] addr_in,
  output logic        data_ready,
  output logic [15:0] data_out,
  // ─── Write Cons Interface ─────────────────────────────────────────────
  input  wire         cons_en,
  input  wire [15:0]  cons_car,
  input  wire [15:0]  cons_cdr,
  output logic        cons_done,
  output logic [15:0] cons_ptr
);
  typedef enum logic [1:0] {
    ConsIdle,
    ConsWriteCar
  } cons_state_t;

  localparam int MemorySize = 256;
  // For now, HeapStart needs to be max memory index + 1. Manually edit.
  localparam int HeapStart = 5; // NIL. Can be pushed forward later if need be. Basically ROM.

  (* ram_style = "block" *)
  logic [15:0] memory[MemorySize];

  logic [11:0] heap_ptr = HeapStart;

  cons_state_t cons_state = ConsIdle;

  initial begin
    memory[0] = LISP_NIL;
    memory[1] = 16'hBEEF;
    memory[2] = 16'hDEAD;
    memory[3] = 16'h0001; // CDR pointer to BEEF
    memory[4] = 16'h0002; // CAR pointer to DEAD
    // expr = 15'h1004 // Cons pointer to cons data
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

  // ─── Cons Write FSM ────────────────────────────────────────────────────
  always_ff @(posedge clk) begin
    cons_done <= 0;
    case (cons_state)
      ConsIdle: begin
        if (cons_en) begin
          memory[heap_ptr] <= cons_cdr;
          heap_ptr         <= heap_ptr + 1;
          cons_state       <= ConsWriteCar;
        end
      end
      ConsWriteCar: begin
        memory[heap_ptr] <= cons_car;
        cons_done            <= 1;
        cons_ptr             <= {1'b0, TYPE_CONS, heap_ptr};
        heap_ptr             <= heap_ptr + 1;
        cons_state           <= ConsIdle;
      end
    endcase
  end

endmodule
