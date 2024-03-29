// Copyright 2023 Thales 
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1

#include "model_test.h"
.macro init
.endm
.section .text.init
.globl _start
.option norvc
.org 0x00
_start:
RVMODEL_BOOT
	la x6, exception_handler  
        csrw mtvec, x6  	## Load the address of the exception handler into MTVEC

	## configuring mcountern CSR  	
	li x1, 0x4
	csrw 0x306, x1

	csrw 0x341, x0  	## Writing Zero to MEPC CSR
    	csrw 0x342, x0  	## Writing Zero to MCAUSE CSR
	
	li x28, 5  		## set x28 to the number of times to read the CSR

	li x8, 0xFFFFFFFD
	csrrw x9, 0xB02, x8     ## Configuring minstret to 0xFFFFFFFD

	csrr x7, 0xB02
	csrr x8, 0xC02 		
	csrr x9, 0xC02
	
read_csr_loop:
		csrr x6, 0xC02 				## Read the current value of instret into x6
   		csrr x7, 0xC02  			## Read the current value of instret again into x7
   		bge  x7, x6, next_instr11  		## if x7 > x6, jump to next instr
    	j csr_fail
    
    	next_instr11 :
    		addi x28, x28, -1	 		## Decrement counter value
	   	bnez x28, read_csr_loop			## If counter is not equal to zero then jump back to loop
	
	j supervisor_mode_code_start
	j csr_fail

supervisor_mode_code_start:
	csrw  0x341, 0    ## Writing zero into MEPC CSR
	csrw  0x342, 0    ## Reading Zero into MCAUSE CSR
        
## Configuring PMP CSRs	
	## set start address range t0 x7
 	la x7, supervisor_code
 	li x28, 0x10000
 	add x7, x7, x28
 	# Enable R,W,X,TOR IN PMPCFG CSR t0 x8
 	li x8, 0x0F
	#set PMPADDR0 CSR with x7
 	csrw 0x3B0, x7
	# set PMPCFG0 CSR with x8
 	csrw 0x3A0, x8

## Configuring MSTATUS MPP bit to 01(supervisor mode)
	# Save the current mode in x28
        csrr x28, 0x300
        # Set the MPP field to supervisor mode (1)
        li x29, 0b1
        slli x29, x29, 11
        addi x28, x29, 0
        # Write the modified MSTATUS value back to the CSR
        csrw 0x300, x28
## Assigning supervisor code starting PC value to MEPC CSR	
	la x28, supervisor_code
        csrw 0x341, x28
	csrr x31, 0x300
       	mret
      
# Supervisor code starts here
supervisor_code:

	csrr x6, 0xC02 					
	csrr x7, 0xC02
   	li x28, 5 					 ## set x28 to the number of times to read the CSR

read_csr_loop2:

		csrr x6, 0xC02 				## Read the current value of instret into x6
   		csrr x7, 0xC02  			## Read the current value of instret again into x7
   		bge  x7, x6, next_instr12 		## if x7 > x6, jump to next instr
    	j csr_fail
    
    	next_instr12 :
    		addi x28, x28, -1			## Decrement counter value
	   	bnez x28, read_csr_loop2		## If counter is not equal to zero then jump back to loop
	
	j user_mode_code_start	
	j csr_fail


user_mode_code_start:
	la x30, user_exception_handler
	csrw stvec, x30

        la x31, user_mode_code
 	csrw sepc, x31

	csrr x28, 0x100 
	li x29, 0b0
	slli x29, x29, 8
        addi x28, x29, 0
	csrw 0x100, x28
	csrr x29, 0x100
		
	sret

## USER Mode code starts here
user_mode_code:
	
	csrr x6, 0xC02 		 
	csrr x7, 0xC02
   	li x28, 5 		 		## set x28 to the number of times to read the CSR
    

read_csr_loop3:
		csrr x6, 0xC02 			## Read the current value of instret into x6
   		csrr x7, 0xC02  		## Read the current value of instret again into x7
   		bge  x7, x6, next_instr13  	## if x7 > x6, jump to next instr
    	j csr_fail
    
    	next_instr13 :
    		addi x28, x28, -1		## Decrement counter value
	   	bnez x28, read_csr_loop3	## If x28 is not equal to zero then jump back to loop	
	j csr_pass

exception_handler:
	csrr x3, 0x300
	srli x3, x3, 11
	andi x3, x3, 0b11
	li x8, 3
	li x9, 1
	beqz x3, user_exception_handler 
	beq x3, x8, machine_exception_handler
	beq x3, x9, supervisor_exception_handler

machine_exception_handler:
	csrr x6, 0x300
        csrr x30, 0x341	  		  ## Reading MEPC CSR which holds exception origin Address		
        csrr x31, 0x342     		  ## Reading MCAUSE CSR which holds the cause of exception
        li x2 ,2
        beq x31, x2, next_instr		  ## Checking is exception is expected exception or not
        j csr_fail

next_instr:
	csrw 0x342, 0			  ## Reseting MCAUSE value to 0 before handling new exception
	beq x30, x0, csr_fail
	j csr_fail

supervisor_exception_handler:
	csrr x30, 0x341	  		  ## Reading MEPC CSR which holds exception origin Address		
        csrr x31, 0x342     		  ## Reading MCAUSE CSR which holds the cause of exception
        li x2 ,2
        beq x31, x2, next_instr1  	  ## Checking is exception is expected exception or not
        j csr_fail

next_instr1:
	beq x30, x0, csr_fail
	j user_mode_code_start

user_exception_handler:
 	csrr x3, 0x100
 	csrr x30, 0x341	 		   ## Reading MEPC CSR which holds exception origin Address		
        csrr x31, 0x342			   ## Reading MCAUSE CSR which holds the cause of exception
 
         li x2 ,2
         beq x31, x2, next_instr2   	   ## Checking is exception is expected exception or not
         j csr_fail
 
next_instr2:
 	csrw 0x342,0			   ## Reseting MCAUSE value to 0 before handling new exception
 	beq x30, x0, csr_fail
	j csr_fail


csr_pass:
	li x1, 0
	slli x1, x1, 1
	addi x1, x1, 1
	sw x1, tohost, t5
	self_loop: j self_loop

csr_fail:
	li x1, 1
	slli x1, x1, 1
	addi x1, x1, 1
	sw x1, tohost, t5
	self_loop_2: j self_loop_2

RVMODEL_DATA_BEGIN
RVMODEL_DATA_END  
