`timescale 1ns / 1ps
`default_nettype none

`include "lisp_defs.sv"

module memory #(
  parameter int HeapStart = 4 // Start of heap cells after ROM/NIL/etc
)(
  input  wire         clk,
  input  wire         rst,
  // ─── Read Interface ──────────────────────────────────────────────
  input  wire         req,
  input  wire  [15:0] addr_in,
  output logic        data_ready,
  output logic [15:0] data_out,
  // ─── Write Interface ─────────────────────────────────────────────
  input  wire         write_enable,
  input  wire  [14:0] data_type,
  input  wire  [15:0] car_data,
  input  wire  [15:0] cdr_data,
  output logic        write_done,
  output logic [15:0] ptr
);
  // Memory layout parameters
  localparam int MemorySize = 256;

  typedef enum {
    WriteHeader,
    WriteCar,
    WriteCdr
  } write_state_t;

  write_state_t write_state = WriteCdr;
  logic [15:0] heap_ptr = HeapStart;

  (* ram_style = "block" *)
  logic [15:0] memory[MemorySize];

  initial begin
    memory[0] = lisp_defs::LISP_NIL;
    memory[1] = lisp_defs::LISP_NIL;
    memory[2] = 16'h789A;
    memory[3] = { 1'b0, lisp_defs::TYPE_NUMBER };
    // memory dump for integer 0x789A
    // [ header, data_0, ptr (nil) ]
    // expr = 15'h0003;
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      // Reset all stateful signals
      data_ready  <= 0;
      data_out    <= 0;
      write_done  <= 0;
      write_state <= WriteCdr;
      heap_ptr    <= HeapStart;
    end else begin
      // --- Read FSM ---
      if (req) begin
        data_out   <= memory[addr_in];
        data_ready <= 1'b1;
      end else begin
        data_ready <= 1'b0;
      end

      write_done <= 0;
      case (write_state)
        WriteCdr: begin
          if (write_enable) begin
            memory[heap_ptr] <= cdr_data;
            heap_ptr         <= heap_ptr + 1;
            write_state      <= WriteCar;
          end
        end
        WriteCar: begin
          memory[heap_ptr] <= car_data;
          heap_ptr         <= heap_ptr + 1;
          write_state      <= WriteHeader;
        end
        WriteHeader: begin
          memory[heap_ptr] <= {1'b0, data_type};
          write_done       <= 1;
          heap_ptr         <= heap_ptr + 1;
          ptr              <= heap_ptr;
          write_state      <= WriteCdr;
        end
      endcase
    end
  end
endmodule
