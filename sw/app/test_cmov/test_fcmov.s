.section .text.init
.globl _start
_start:
  .fill 32, 4, 0x00000013  # Remplit avec des NOP

  # Charger les constantes flottantes en mémoire
  # 3.0 = 0x40400000, 0.0 = 0x00000000, 8.0 = 0x41000000
  li   t0, 0x40400000      # 3.0f en hex
  li   t1, 0x41000000      # 8.0f en hex
  li   t2, 0x80001100      # adresse temporaire pour les constantes

  sw   t0, 0(t2)
  sw   zero, 4(t2)
  sw   t1, 8(t2)

  flw  ft0, 0(t2)          # ft0 = 3.0  (rs1)
  flw  ft1, 4(t2)          # ft1 = 0.0  (rs2 → condition: rs2==0 → prend rs1)
  flw  ft2, 8(t2)          # ft2 = 8.0  (rs3)

  # Check normal behavior
  # ft1 == 0.0 donc ft3 = ft0 = 3.0
  .insn r4 0x0b, 0, 1, ft3, ft0, ft1, ft2

  # Check if forwarding works for rs3
  # ft1 = 1.0, ft2 = ft2 + ft3
  li   t0, 0x3F800000      # 1.0f en hex
  sw   t0, 0(t2)
  flw  ft1, 0(t2)          # ft1 = 1.0  (rs2 → condition: rs2!=0 → prend rs3)

  fadd.s ft2, ft2, ft3     # ft2 = ft2 + ft3 (equivalent add t2, t2, t3)

  # ft1 != 0.0 donc ft3 = ft2
  .insn r4 0x0b, 0, 1, ft3, ft0, ft1, ft2

  # Check if stalling works for rs3
  li   t4, 0x80001000
  li   t0, 0x40A00000      # 5.0f en hex
  sw   t0, 0(t2)
  flw  ft5, 0(t2)          # ft5 = 5.0

  fadd.s ft2, ft2, ft5     # ft2 = ft2 + 5.0 (equivalent add t2, t2, 5)

  fsw  ft2, 0(t4)
  flw  ft2, 0(t4)

  # ft1 != 0.0 donc ft3 = ft2
  .insn r4 0x0b, 0, 1, ft3, ft0, ft1, ft2
