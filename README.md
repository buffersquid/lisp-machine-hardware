# LISP Machine Hardware Implementation Plan

## Phase 1: Data Representation and Memory

### 1. Tagged Pointer System
- Define a tagged pointer format (e.g., 16-bit: 3-bit type, 13-bit address)
- Types: `NUMBER`, `SYMBOL`, `CONS`, `CLOSURE`, `RETURN_ADDR`, etc.

### 2. List Cell Memory (Heap)
- Implement memory as RAM containing list cells
- Each list cell = `{car, cdr}` (pointers)

### 3. Storage Manager FSM
- Handles multi-cycle operations:
  - `CAR` / `CDR`: 2 cycles
  - `CONS`: 3 cycles (cdr → car → return pointer)

---

## Phase 2: Registers and Evaluator State Machine

### 1. Define Core Registers
- `EXP`: Expression being evaluated
- `ENV`: Current environment
- `VAL`: Result of evaluation
- `ARGS`: Argument list for function calls
- `CLINK`: Control stack for return addresses

### 2. Build State Machine
- Dispatch based on `TYPE(EXP)`:
  - `NUMBER` → `SELF`
  - `VARIABLE` → `LOOKUP`
  - `IF` → `IF1 → IF2`
  - `COMBINATION` → `EVCOMB → CALL`

### 3. Implement CLINK Stack
- Use CONS-based linked list
- Return addresses encoded as tagged pointers (`EVCOMB3`, `IF2`, etc.)

---

## Phase 3: Primitive Operator Execution

- Add basic operators:
  - `CAR`, `CDR`, `CONS`
  - `ATOM`, `EQ`, `QUOTE`
- Implement as type-dispatchable opcodes
- Integrate into `EVAL` and `APPLY`

---

## Phase 4: Closure and Function Call Support

- Define closure object: `(&PROCEDURE formals body env)`
- Add `FUNCALL` logic
- Implement `BIND` and extend ENV format
- Evaluate `(LAMBDA ...)`, apply to ARGS

---

## Phase 5: Program Loading and I/O

- Add program loading from ROM or external interface
- Minimal I/O:
  - UART
  - LEDs for debugging
- Optional: simple REPL over serial

---

## Phase 6: Optional Extensions

- Garbage Collection FSM
- Symbol table and interning
- Bytecode compiler to typed-pointer representation
- More advanced primitives (`+`, `*`, etc.)
- Debug tools (stepper, breakpoint, waveform dump)

---

## Planned Build Order

1. [ ] Implement tagged memory layout (RAM with type-tagged words)
2. [ ] Write a testbench to verify `CONS`, `CAR`, `CDR` FSM
3. [ ] Build register file and FSM controller
4. [ ] Implement `TYPE-DISPATCH`-based `EVAL`
5. [ ] Handle `QUOTE`, `IF`, and `LAMBDA`
6. [ ] Add `APPLY`, `BIND`, `LOOKUP`
7. [ ] Evaluate a static program from RAM

