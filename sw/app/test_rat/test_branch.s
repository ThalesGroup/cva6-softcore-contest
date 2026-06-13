.section .text.init
.globl _start

_start :

  .fill 32, 4, 0x00000013 # Remplit avec des NOP (li x0, 0)
  li  t0, 3
  li  t1, 3


  # checking rollback
  loop :
  sub t0, t0, 1
  beqz t0 suite
  b loop

  suite :
  div t1, t1, 0 #should raise an exception and restore rat


