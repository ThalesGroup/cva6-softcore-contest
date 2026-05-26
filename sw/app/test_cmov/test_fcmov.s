.section .init
.global _start

_start:
    # Ce bloc est placé dans .init, donc pile à l'adresse de boot physique!
    j actual_code

.section .text
actual_code:

    .fill 32, 4, 0x00000013  # Remplit avec des NOP
    # === 1. Activer le FPU ===
    lui  t0, 0x2
    nop
    nop
    csrw mstatus, t0
    nop
    nop

    # === Préparer les constantes FP (Espacées de 8 octets pour le L1 Cache, j'ai eu des problème
    # quand c'était pas alignés sur 8 octet) ===
    la   t2, buffer

    li   t0, 0x40400000      # 3.0f
    sw   t0, 0(t2)

    li   t0, 0x00000000      # 0.0f
    sw   t0, 8(t2)

    li   t1, 0x41000000      # 8.0f
    sw   t1, 16(t2)

    fence
    fence.i

    # chargement dans les registres FPU
    flw  ft0, 0(t2)
    flw  ft1, 8(t2)
    flw  ft2, 16(t2)
    nop
    nop

    # test comportement normal
    .insn r4 0x0b, 1, 0, ft3, ft0, ft1, ft2

    # test forwarding rs3
    li   t0, 0x3F800000      # 1.0f
    sw   t0, 0(t2)
    nop
    flw  ft1, 0(t2)
    fadd.s ft2, ft2, ft3
    .insn r4 0x0b, 1, 0, ft3, ft0, ft1, ft2

    # test stall rs3
    li   t0, 0x40A00000      # 5.0f
    sw   t0, 0(t2)
    nop
    flw  ft2, 0(t2)
    .insn r4 0x0b, 1, 0, ft3, ft0, ft1, ft2

end:
    j end

.section .data
.align 4
buffer:
    .zero 32
