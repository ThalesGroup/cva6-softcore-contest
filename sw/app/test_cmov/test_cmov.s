.section .text.init
.globl _start

_start :

  .fill 32, 4, 0x00000013 # Remplit avec des NOP (li x0, 0)
  li  t0, 3
  li  t1, 0
  li  t2, 8

  #Check normal behavior
  .insn r4 0x0b, 0, 0, t3, t0, t1, t2


  #Check if forwarding works for rs3

  li t1, 1

  add t2, t2, t3

  .insn r4 0x0b, 0, 0, t3, t0, t1, t2

  #check if stalling works for rs3

  li t4, 0x80001000

  add t2, t2, 5

  sw t2, 0(t4)

  lw t2, 0(t4)

  .insn r4 0x0b, 0, 0, t3, t0, t1, t2



