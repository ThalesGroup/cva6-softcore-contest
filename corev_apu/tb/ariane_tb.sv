// Copyright (c) 2020 Thales.
// Copyright 2018 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.
//
// Author: Florian Zaruba, ETH Zurich
// Date: 15/04/2017
//
// Additional contributions by:
//         Sebastien Jacq - sjthales on github.com
//
// Description: Top level testbench module. Instantiates the top level DUT, configures
//              the virtual interfaces and starts the test passed by +UVM_TEST+
//
// =========================================================================== //
// Revisions  :
// Date        Version  Author       Description
// 2020-10-06  0.1      S.Jacq       modification of the Test for CVA6 softcore
// =========================================================================== //

import ariane_pkg::*;
import jtag_pkg::*;

//`include "uvm_macros.svh"

`define MAIN_MEM(P) dut.i_sram.gen_cut[0].i_tc_sram_wrapper.i_tc_sram.init_val[(``P``)]
// `define USER_MEM(P) dut.i_sram.gen_cut[0].gen_mem.gen_mem_user.i_tc_sram_wrapper_user.i_tc_sram.init_val[(``P``)]

//import "DPI-C" function read_elf(input string filename);
//import "DPI-C" function byte get_section(output longint address, output longint len);
//import "DPI-C" context function void read_section(input longint address, inout byte buffer[]);

module ariane_tb;

    logic [255:0][31:0]   jtag_data;

    jtag_pkg::debug_mode_if_t  debug_mode_if = new;

    logic [8:0] jtag_conf_reg, jtag_conf_rego; //22bits but actually only the last 9bits are used
    localparam BEGIN_MEM_INSTR = 32'h80000080;

    // cva6 configuration
    localparam config_pkg::cva6_cfg_t CVA6Cfg = cva6_config_pkg::cva6_cfg;
    localparam bit IsRVFI = bit'(cva6_config_pkg::CVA6ConfigRvfiTrace);
    localparam type rvfi_instr_t = struct packed {
        logic [config_pkg::NRET-1:0]                  valid;
        logic [config_pkg::NRET*64-1:0]               order;
        logic [config_pkg::NRET*config_pkg::ILEN-1:0] insn;
        logic [config_pkg::NRET-1:0]                  trap;
        logic [config_pkg::NRET*riscv::XLEN-1:0]      cause;
        logic [config_pkg::NRET-1:0]                  halt;
        logic [config_pkg::NRET-1:0]                  intr;
        logic [config_pkg::NRET*2-1:0]                mode;
        logic [config_pkg::NRET*2-1:0]                ixl;
        logic [config_pkg::NRET*5-1:0]                rs1_addr;
        logic [config_pkg::NRET*5-1:0]                rs2_addr;
        logic [config_pkg::NRET*riscv::XLEN-1:0]      rs1_rdata;
        logic [config_pkg::NRET*riscv::XLEN-1:0]      rs2_rdata;
        logic [config_pkg::NRET*5-1:0]                rd_addr;
        logic [config_pkg::NRET*riscv::XLEN-1:0]      rd_wdata;
        logic [config_pkg::NRET*riscv::XLEN-1:0]      pc_rdata;
        logic [config_pkg::NRET*riscv::XLEN-1:0]      pc_wdata;
        logic [config_pkg::NRET*riscv::VLEN-1:0]      mem_addr;
        logic [config_pkg::NRET*riscv::PLEN-1:0]      mem_paddr;
        logic [config_pkg::NRET*(riscv::XLEN/8)-1:0]  mem_rmask;
        logic [config_pkg::NRET*(riscv::XLEN/8)-1:0]  mem_wmask;
        logic [config_pkg::NRET*riscv::XLEN-1:0]      mem_rdata;
        logic [config_pkg::NRET*riscv::XLEN-1:0]      mem_wdata;
    };

   /* static uvm_cmdline_processor uvcl = uvm_cmdline_processor::get_inst();

    localparam int unsigned CLOCK_PERIOD = 20ns;
    // toggle with RTC period
    localparam int unsigned RTC_CLOCK_PERIOD = 30.517us;*/

   localparam int unsigned CLOCK_PERIOD = 25ns; //40MHz as for the Zybo kit

    localparam NUM_WORDS = 2**18;
    logic clk_i;
    logic rst_ni;
    logic rtc_i;

    longint unsigned cycles;
    longint unsigned max_cycles;
    
    logic        jtag_TDO_driven;

    logic        jtag_TRSTn = 1'b0;
    logic        jtag_TCK   = 1'b0;
    logic        jtag_TDI   = 1'b0;
    logic        jtag_TMS   = 1'b0;
    logic        jtag_TDO_data;

    string binary_mem ;

    ariane_testharness #(
        .CVA6Cfg ( CVA6Cfg ),
        .IsRVFI ( IsRVFI ),
        .rvfi_instr_t ( rvfi_instr_t ),
        //
        .NUM_WORDS         ( NUM_WORDS ),
        .InclSimDTM        ( 1'b0      ),
        .StallRandomOutput ( 1'b1      ),
        .StallRandomInput  ( 1'b1      )
    ) dut (
        .clk_i,
        .rst_ni,
        .rtc_i,
        .jtag_TCK,
        .jtag_TMS,
        .jtag_TDI,
        .jtag_TRSTn,
        .jtag_TDO_data,
        .jtag_TDO_driven
    );



    // Clock process
    initial begin
        clk_i = 1'b0;
        //rst_ni = 1'b0;
        repeat(8)
            #(CLOCK_PERIOD/2) clk_i = ~clk_i;
        //rst_ni = 1'b1;
        forever begin
            #(CLOCK_PERIOD/2) clk_i = 1'b1;
            #(CLOCK_PERIOD/2) clk_i = 1'b0;

            //if (cycles > max_cycles)
            //    $fatal(1, "Simulation reached maximum cycle count of %d", max_cycles);

            //cycles++;
        end
    end

   /* initial begin
        forever begin
            rtc_i = 1'b0;
            #(RTC_CLOCK_PERIOD/2) rtc_i = 1'b1;
            #(RTC_CLOCK_PERIOD/2) rtc_i = 1'b0;
        end
    end
*/
    // testbench driver process
    initial
    begin
        logic [1:0]  dm_op;
        logic [31:0] dm_data;
        logic [6:0]  dm_addr;
        logic        error;
        automatic logic [9:0]  FC_CORE_ID = {5'd0,5'd0};

        $display("[TB] %t - Asserting hard reset", $realtime);
        rst_ni = 1'b0;

        #10ns
       
        jtag_pkg::jtag_reset(jtag_TCK, jtag_TMS, jtag_TRSTn, jtag_TDI);
        jtag_pkg::jtag_softreset(jtag_TCK, jtag_TMS, jtag_TRSTn, jtag_TDI);
        #5us;
    
        rst_ni = 1'b1;

        debug_mode_if.init_dmi_access(jtag_TCK, jtag_TMS, jtag_TRSTn, jtag_TDI);
        $display("[TB] %t - init_dmi_access", $realtime);
        
        debug_mode_if.set_dmactive(1'b1, jtag_TCK, jtag_TMS, jtag_TRSTn, jtag_TDI, jtag_TDO_data);
        $display("[TB] %t - set_dmactive", $realtime);
    
        debug_mode_if.set_hartsel(FC_CORE_ID, jtag_TCK, jtag_TMS, jtag_TRSTn, jtag_TDI, jtag_TDO_data);
        $display("[TB] %t - set_hartsel", $realtime);

   	$display("[TB] %t - Halting the Core", $realtime);
    	debug_mode_if.halt_harts(jtag_TCK, jtag_TMS, jtag_TRSTn, jtag_TDI, jtag_TDO_data);
    

        $value$plusargs("binary_mem=%s", binary_mem);
        $display("Loading application to memory from %s", binary_mem);
        //$readmemh(binary_mem, dut.i_sram.genblk1[0].genblk1.i_ram.Mem_DP);  
        $readmemh(binary_mem, dut.i_sram.gen_cut[0].i_tc_sram_wrapper.i_ram.Mem_DP);  

    
        // write dpc to addr_i so that we know where we resume
	$display("[TB] %t - Writing the boot address into dpc", $realtime);
        debug_mode_if.write_reg_abstract_cmd(riscv::CSR_DPC, BEGIN_MEM_INSTR, jtag_TCK, jtag_TMS, jtag_TRSTn, jtag_TDI, jtag_TDO_data);

    
        // we have set dpc and loaded the binary, we can go now
        $display("[TB] %t - Resuming the CORE", $realtime);
        debug_mode_if.resume_harts(jtag_TCK, jtag_TMS, jtag_TRSTn, jtag_TDI, jtag_TDO_data);

    end

endmodule
