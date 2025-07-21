`timescale 1ns / 1ps
`default_nettype none

`include "lisp_defs.sv"

module memory #(
  parameter int HeapStart = 4 // Start of heap cells after ROM/NIL/etc
)(
  input  wire         clk,
  input  wire         rst,
  // ─── Read Interface ──────────────────────────────────────────────
  input  wire         read_enable,
  input  wire  [15:0] addr_in,
  output logic [14:0] header_out,
  output logic [15:0] car_out, cdr_out,
  // ─── Write Interface ─────────────────────────────────────────────
  input  wire         write_enable,
  input  wire  [14:0] data_type,
  input  wire  [15:0] car_data, cdr_data,
  output logic [15:0] ptr,
  // ─── General ─────────────────────────────────────────────────────
  output logic        done
);
  // Memory layout parameters
  localparam int MemorySize = 256;

  typedef enum {
    Idle,
    ReadHeader,
    ReadCar,
    ReadCdr,
    WriteHeader,
    WriteCar,
    WriteCdr
  } state_t;

  state_t state = Idle;
  logic [15:0] heap_ptr = HeapStart;

  (* ram_style = "block" *)
  logic [15:0] memory[MemorySize];

  initial begin
    memory['h0] = lisp_defs::NIL;
    // first number
    memory['h1] = lisp_defs::NIL;
    memory['h2] = 16'h0005;
    memory['h3] = { 1'b0, lisp_defs::TYPE_NUMBER };
    // second number
    memory['h4] = lisp_defs::NIL;
    memory['h5] = 16'h0003;
    memory['h6] = { 1'b0, lisp_defs::TYPE_NUMBER };
    // (3 nil)
    memory['h7] = lisp_defs::NIL;
    memory['h8] = 16'h0006;
    memory['h9] = { 1'b0, lisp_defs::TYPE_CONS };
    // (5 (3 nil))
    memory['hA] = 16'h0009;
    memory['hB] = 16'h0003;
    memory['hC] = { 1'b0, lisp_defs::TYPE_CONS };
    // (+ (5 (3 nil)))
    memory['hD] = 16'h000C;
    memory['hE] = 16'h0012;
    memory['hF] = { 1'b0, lisp_defs::TYPE_CONS };
    // Addition
    memory['h10] = lisp_defs::NIL;
    memory['h11] = lisp_defs::PRIMOP_ADD;
    memory['h12] = { 1'b0, lisp_defs::TYPE_PRIMITIVE };
    // memory dump for (+ 5 3) = (+ (5 (3 nil)))
    // expr = 15'h000F;
  end

  always_ff @(posedge clk) begin
    done <= 0;
    if (rst) begin
      // Reset all stateful signals
      state    <= Idle;
      heap_ptr <= HeapStart;
    end else begin
      case (state)
        Idle: begin
          if (read_enable) begin
            state <= ReadHeader;
          end else if (write_enable) begin
            state <= WriteCdr;
          end else begin
            state <= Idle;
          end
        end

        // --- Read FSM ---
        ReadHeader: begin
          // Warning: this is being trimmed because our memory space is
          // currently only 256 words. I think it's not an issue for now.
          header_out <= memory[addr_in][14:0];
          state      <= ReadCar;
        end
        ReadCar: begin
          car_out <= memory[addr_in - 1];
          state   <= ReadCdr;
        end
        ReadCdr: begin
          cdr_out <= memory[addr_in - 2];
          done    <= 1;
          state   <= Idle;
        end

        // --- Write FSM ---
        WriteCdr: begin
          memory[heap_ptr] <= cdr_data;
          heap_ptr         <= heap_ptr + 1;
          state            <= WriteCar;
        end
        WriteCar: begin
          memory[heap_ptr] <= car_data;
          heap_ptr         <= heap_ptr + 1;
          state            <= WriteHeader;
        end
        WriteHeader: begin
          memory[heap_ptr] <= {1'b0, data_type};
          done             <= 1;
          heap_ptr         <= heap_ptr + 1;
          ptr              <= heap_ptr;
          state            <= Idle;
        end
      endcase
    end
  end
endmodule
