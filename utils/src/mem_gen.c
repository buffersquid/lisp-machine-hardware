#include <stdint.h>
#include <stdio.h>

typedef enum {
  NUMBER,
  SYMBOL,
  CONS,
} tag_t;

// typedef struct here so we will get errors from typechecker
// If we just did typedef uint16_t memory_t, it's equal to all
// other uint16_t types, which may cause bugs in the future.
typedef struct {
  uint16_t value;
} memory_t;

#define MEMORY_SIZE 256

memory_t memory[MEMORY_SIZE];
memory_t *heap_ptr = memory;

uint16_t get_memory_offset(memory_t *ptr) { return (uint16_t)(ptr - memory); }

tag_t get_type(memory_t word) { return (tag_t)((word.value & 0x7000) >> 12); }

uint16_t get_mem_index(memory_t word) { return word.value & 0x0FFF; }

memory_t construct_tagged_pointer(tag_t type, uint16_t memory_location) {
  return (memory_t){(0 << 15) | ((type & 0x7) << 12) |
                    (memory_location & 0x0FFF)};
}

memory_t allocate_number(uint16_t number) {
  heap_ptr += 1;
  (*heap_ptr).value = number;
  return construct_tagged_pointer(NUMBER, get_memory_offset(heap_ptr));
}

memory_t allocate_cons(memory_t car, memory_t cdr) {
  heap_ptr += 2;
  *(heap_ptr - 1) = cdr;
  *heap_ptr = car;
  return construct_tagged_pointer(CONS, get_memory_offset(heap_ptr));
}

void dump_memory() {
  printf("--- memory dump ---\n");
  printf("[%#06x]: %#06x\n", 0, memory[0].value); // NIL
  for (int i = 0; i < MEMORY_SIZE; i++) {
    if (memory[i].value != 0) {
      printf("[%#06x]: %#06x\n", i, memory[i].value);
    }
  }
  printf("---  end dump  ---\n");
}

int main() {
  memory_t EXPR = allocate_cons(allocate_number(0x123), allocate_number(0x456));
  dump_memory();
  printf("%#06x\n", EXPR.value);
}
