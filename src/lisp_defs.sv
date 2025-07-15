`timescale 1ns / 1ps
`default_nettype none

package lisp_defs;

  //────────────────────────────────────────────────────────────
  // Basic Types
  //────────────────────────────────────────────────────────────
  typedef logic [11:0] address_t;

  typedef enum logic [2:0] {
    TYPE_NUMBER = 3'b000,
    TYPE_CONS   = 3'b001
  } tag_t;

  typedef enum logic [3:0] {
    SelectExpr,
    Fetch,
    MemWait,
    EvalConst,
    EvalCar,
    Apply,
    Halt,
    Error
  } state_t;

  typedef struct packed {
    logic     active;
    address_t address;
    state_t   continue_state;
  } memory_read_t;

  //────────────────────────────────────────────────────────────
  // Constants
  //────────────────────────────────────────────────────────────
  parameter logic [15:0] LISP_NIL = 16'h0000;

  // Special memory layout parameters
  parameter int MemorySize = 256;
  parameter int HeapStart  = 5;   // Start of heap cells after ROM/NIL/etc.

  // Error codes
  parameter logic [15:0] STATE_ERROR = 16'h6666;
  parameter logic [15:0] FETCH_ERROR = 16'hAAAA;

endpackage
