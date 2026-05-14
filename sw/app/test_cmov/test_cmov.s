.section .text.init
.globl _start

_start :

  .fill 32, 4, 0x00000013 # Remplit avec des NOP (li x0, 0)
  li  t0, 3
  li  t1, 0
  li  t2, 8


  .insn r4 0x0b, 0, 0, t3, t0, t1, t2

  bne t3, t0, fail

  success :
    li a0, 0
    j end

  fail :
    li a0, 1
    j end

  end :
    ret






