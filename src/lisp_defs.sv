`ifndef LISP_DEFS_SV
`define LISP_DEFS_SV

`timescale 1ns / 1ps
`default_nettype none

package lisp_defs;

  //────────────────────────────────────────────────────────────
  // Basic Types
  //────────────────────────────────────────────────────────────
  typedef enum logic [15:0] {
    TYPE_NUMBER    = 16'h0,
    TYPE_CONS      = 16'h1,
    TYPE_PRIMITIVE = 16'h2
  } tag_t;

  typedef enum logic [15:0] {
    PRIMOP_ADD = 16'h0
  } primitive_t;

  //────────────────────────────────────────────────────────────
  // Constants
  //────────────────────────────────────────────────────────────
  localparam logic [15:0] LISP_NIL = 16'h0000;

endpackage

`endif
