.section .data
.align 4
buffer:
  .word 0
  .word 0
  .word 0
  .word 0           # pour fsw plus tard
  .word 0
  .word 0

.section .text.init
.globl _start
_start:
  # === 1. Activer le FPU (OBLIGATOIRE) ===
  li   t0, 0x6000
  csrs mstatus, t0

  # === 2. NOPs (si vraiment nécessaire) ===
  .fill 32, 4, 0x00000013

  # === 3. Préparer les constantes FP ===
  la   t2, buffer

  li   t0, 0x40400000      # 3.0f
  sw   t0, 0(t2)
  sw   zero, 4(t2)         # 0.0f
  li   t1, 0x41000000      # 8.0f
  sw   t1, 8(t2)

  flw  ft0, 0(t2)
  flw  ft1, 4(t2)
  flw  ft2, 8(t2)

  # === 4. Test FCMOV normal ===
  # ft1 == 0.0 → ft3 = ft0 = 3.0
  .insn r4 0x0b, 0, 1, ft3, ft0, ft1, ft2

  # === 5. Test forwarding rs3 ===
  li   t0, 0x3F800000      # 1.0f
  sw   t0, 0(t2)
  flw  ft1, 0(t2)          # ft1 = 1.0

  fadd.s ft2, ft2, ft3     # ft2 utilisé immédiatement après

  .insn r4 0x0b, 0, 1, ft3, ft0, ft1, ft2

  # === 6. Test stall rs3 ===
  li   t0, 0x40A00000      # 5.0f
  sw   t0, 0(t2)
  flw  ft5, 0(t2)

  fadd.s ft2, ft2, ft5

  fsw  ft2, 12(t2)
  flw  ft2, 12(t2)

  .insn r4 0x0b, 0, 1, ft3, ft0, ft1, ft2

end:
  j end
