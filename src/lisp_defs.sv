`ifndef LISP_DEFS_SV
`define LISP_DEFS_SV

`timescale 1ns / 1ps
`default_nettype none

package lisp_defs;

  //────────────────────────────────────────────────────────────
  // Basic Types
  //────────────────────────────────────────────────────────────
  typedef enum logic [2:0] {
    TYPE_NUMBER = 3'b000,
    TYPE_CONS   = 3'b001
  } tag_t;

  //────────────────────────────────────────────────────────────
  // Constants
  //────────────────────────────────────────────────────────────
  localparam logic [15:0] LISP_NIL = 16'h0000;

endpackage

`endif
