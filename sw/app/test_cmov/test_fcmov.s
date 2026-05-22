.section .init
.global _start

_start:
    # Ce bloc est placé dans .init, donc pile à l'adresse de boot physique!
    j actual_code

.section .text
actual_code:
    # === 1. Activer le FPU ===
    lui  t0, 0x2
    nop
    nop
    csrw mstatus, t0
    nop
    nop

    # === Préparer les constantes FP (Espacées de 8 octets pour le L1 Cache) ===
    la   t2, buffer

    li   t0, 0x40400000      # 3.0f
    sw   t0, 0(t2)           # ft0 sera à buffer + 0

    li   t0, 0x00000000      # 0.0f
    sw   t0, 8(t2)           # ft1 sera à buffer + 8 (Nouvelle frontière 64-bit)

    li   t1, 0x41000000      # 8.0f
    sw   t1, 16(t2)          # ft2 sera à buffer + 16 (Nouvelle frontière 64-bit)

    # Le fence force le Write Buffer du HPDCACHE à tout valider d'un coup
    fence
    fence.i                  # Optionnel mais recommandé : synchronise les pipelines

    # === Chargement dans les registres FPU ===
    flw  ft0, 0(t2)          # Reçoit 3.0f
    flw  ft1, 8(t2)          # Reçoit 0.0f
    flw  ft2, 16(t2)         # Reçoit 8.0f (Sera valide cette fois-ci !)
    nop
    nop

    # === 4. Test FCMOV normal ===
    .insn r4 0x0b, 1, 0, ft3, ft0, ft1, ft2

    # === 5. Test forwarding rs3 ===
    li   t0, 0x3F800000      # 1.0f
    sw   t0, 0(t2)
    nop
    flw  ft1, 0(t2)          # ft1 = 1.0
    fadd.s ft2, ft2, ft3
    .insn r4 0x0b, 1, 0, ft3, ft0, ft1, ft2

    # === 6. Test stall rs3 ===
    li   t0, 0x40A00000      # 5.0f
    sw   t0, 0(t2)
    nop
    flw  ft5, 0(t2)
    fadd.s ft2, ft2, ft5
    fsw  ft2, 12(t2)
    nop
    flw  ft2, 12(t2)
    .insn r4 0x0b, 1, 0, ft3, ft0, ft1, ft2

end:
    j end

# =========================================================
# VRAIE SECTION DE DONNÉES ACCESSIBLE EN LECTURE/ÉCRITURE
# =========================================================
.section .data
.align 4
buffer:
    .zero 32
