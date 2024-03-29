#=======================================================================
# Access satp in M, S, and U mode using csrrw, csrrc, csrrs
#-----------------------------------------------------------------------
# Test Description:
#
# Satp is only accessible in M and S mode and illegal instruction
# exception is generated when accessed in lower privilege mode.
# 
#=======================================================================

#include "macros.h"

#define ALL_F_S  0xffffffff
#define _MMODE_  "M"
#define _SUMODE_ "SU"

.text
.global _start
.option norvc

_start:

    ALL_MEM_PMP                                       # PMP permission to all the memory
    la t1,trap_handler                                # loads the address of trap handler 
    csrw mtvec,t1                                     # sets the mtvec to trap handler 

    li s1, ALL_F_S                                    # loads the random value in s1                         
    li s2, SATP32_PPN                                 # loads the SATP32_PPN value in s2    
    li s3, SATP32_ASID                                # loads the SATP32_ASID value in s3

machine_mode:

    csrc satp,s1                                      # tests the satp access in M mode using csrc     
    csrs satp,s2                                      # tests the satp access in M mode using csrs    
    csrw satp,s3                                      # tests the satp access in M mode using csrw    
    la t5, supervisor_mode                            # loads the supervisor_mode label                   
    CHANGE_T0_S_MODE(t5)                              # changes mode from M to S

supervisor_mode:

    csrc satp,s1                                      # tests the satp access in S mode using csrc    
    csrs satp,s2                                      # tests the satp access in S mode using csrs
    csrw satp,s3                                      # tests the satp access in S mode using csrw              
    SMODE_ECALL                                       # ecall to go back to M mode                                          
    la t5, pre_user_mode                              # loads the user_mode label                   
    CHANGE_T0_U_MODE(t5)                              # changes mode from M to U

pre_user_mode:

    TEST_PROLOG(user_mode,CAUSE_ILLEGAL_INSTRUCTION)  # load the MEPC addr and expected cause 

user_mode:

    csrc satp,s1                                      # tests the satp access in S mode using csrc        
    UMODE_ECALL                                       # ecall to go back to M mode   
    j test_pass                                       # jumps to exit label    

trap_handler:

    csrr t0, mcause                                   # read the value of mcause 
    la t1, rvtest_check                               # load the address of trvtest_check
    
    lw t2, 0(t1)                                      # if cause expected then load 1 else 0
    lw t3, 4(t1)                                      # load the expected value of mepc 
    lw t4, 8(t1)                                      # load the expected value of mcause  

    li  t1, CAUSE_SUPERVISOR_ECALL                    # load the value of supervisor ecall
    beq t0,t1,continue_in_m_mode                      # checks if ecall is occured

    li  t1, CAUSE_USER_ECALL                          # load the value of user ecall
    beq t0,t1,continue_in_m_mode                      # checks if ecall is occured

    beqz t2, test_fail                                # Jumps to exit if cause is not expected
 
    csrr t5,mepc                                      # read the value of mepc 
    bne t3,t5,test_fail                               # check the value of mepc with it's expected value
    
    bne  t0, t4, test_fail                            # jumps to exit if EXPECTED_CAUSE is'nt equal to mcause

continue_execution:

    INCREMENT_MEPC   _SUMODE_                         # update the value of mepc
    j trap_epilogs

continue_in_m_mode:

    INCREMENT_MEPC   _MMODE_                          # update the value of mepc
    li t1,MSTATUS_MPP                                 # update the MPP to MSTATUS_MPP for M mode
    csrs mstatus,t1                                   # update the value mstatus MPP

trap_epilogs:

    la t1, rvtest_check                               # load the addr of rvtest_check
    li t2, 0
    sw t2, 0(t1)                                      # Clear the expected cause
    sw t2, 4(t1)                                      # Clear the exception PC
    sw t2, 8(t1)                                      # Clear cause execution number
    mret
    
test_pass:

    li x1, 0                                          # Write 0 in x1 if test pass
    j exit                                            # Jump to exit

test_fail:

    li x1, 1                                          # Write 1 in x1 if test failed

COREV_VERIF_EXIT_LOGIC                                # exit logic 

.data  
    rvtest_check: 
      .word 0xdeadbeef                                # 1 for cause expected 0  for no cause 
      .word 0xbeefdead                                # write the value of mepc here (where  cause is expected)
      .word 0xcafecafe                                # write the value of expect cause 
.align 12                                     
    rvtest_data:   
      .word 0xbeefcafe                                                 
      .word 0xdeadcafe      
                                                                                                                       
.align 4; .global tohost;   tohost:   .dword 0;
.align 4; .global fromhost; fromhost: .dword 0;
