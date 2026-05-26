#!/bin/bash

# Variables
ASM_FILE="test_cmov.s"
OBJ_FILE="test_cmov.o"
ELF_FILE="test_cmov.riscv"
BIN_FILE="test_cmov.bin"
MEM_FILE="test_cmov.mem"
LINKER_SCRIPT="../../bsp/config/link.ld"
OUTPUT_DIR="../"

echo "=== Compilation de $ASM_FILE ==="

# Étape 1 : Assemblage
riscv64-unknown-elf-gcc -march=rv32im -mabi=ilp32 -c $ASM_FILE -o $OBJ_FILE
if [ $? -ne 0 ]; then
	echo "ERREUR : assemblage échoué"
	exit 1
fi
echo "✓ Assemblage OK"

# Étape 2 : Édition de liens
riscv64-unknown-elf-ld -m elf32lriscv -T $LINKER_SCRIPT $OBJ_FILE -o $ELF_FILE
if [ $? -ne 0 ]; then
	echo "ERREUR : édition de liens échouée"
	exit 1
fi
echo "✓ Édition de liens OK"

# Étape 3 : Création du binaire
riscv64-unknown-elf-objcopy -O binary $ELF_FILE $BIN_FILE
if [ $? -ne 0 ]; then
	echo "ERREUR : objcopy échoué"
	exit 1
fi
echo "✓ Binaire OK"

# Étape 4 : Conversion en .mem
python3 ../../utils/bin2mem.py $BIN_FILE
if [ $? -ne 0 ]; then
	echo "ERREUR : conversion .mem échouée"
	exit 1
fi
echo "✓ Conversion .mem OK"

# Étape 5 : Déplacement du .mem
mv $MEM_FILE $OUTPUT_DIR
if [ $? -ne 0 ]; then
	echo "ERREUR : déplacement du .mem échoué"
	exit 1
fi
echo "✓ $MEM_FILE déplacé vers $OUTPUT_DIR"

echo "=== Compilation terminée avec succès ==="
