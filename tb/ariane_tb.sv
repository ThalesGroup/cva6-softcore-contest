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

`define EXIT_SUCCESS  0
`define EXIT_FAIL     1
`define EXIT_ERROR   -1

module ariane_tb;

    logic [255:0][31:0]   jtag_data;

    jtag_pkg::debug_mode_if_t  debug_mode_if = new;

    logic [8:0] jtag_conf_reg, jtag_conf_rego; //22bits but actually only the last 9bits are used
    localparam BEGIN_MEM_INSTR = 32'h80000080;

    int exit_status = `EXIT_ERROR;

    localparam int unsigned CLOCK_PERIOD = 40ns; //25MHz as for the Zybo kit

    localparam NUM_WORDS = 2**18;
    logic clk_i;
    logic rst_ni;
    logic rtc_i;

    logic        jtag_TDO_driven;

    logic        jtag_TRSTn = 1'b0;
    logic        jtag_TCK   = 1'b0;
    logic        jtag_TDI   = 1'b0;
    logic        jtag_TMS   = 1'b0;
    logic        jtag_TDO_data;

    string binary_mem ;

    // Device under test instance
    ariane_testharness #(
        .NUM_WORDS         ( NUM_WORDS ),
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
        repeat(8)
            #(CLOCK_PERIOD/2) clk_i = ~clk_i;
        forever begin
            #(CLOCK_PERIOD/2) clk_i = 1'b1;
            #(CLOCK_PERIOD/2) clk_i = 1'b0;
        end
    end


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

        debug_mode_if.set_dmactive(1'b1, jtag_TCK, jtag_TMS, jtag_TRSTn, jtag_TDI, jtag_TDO_data);
    
        debug_mode_if.set_hartsel(FC_CORE_ID, jtag_TCK, jtag_TMS, jtag_TRSTn, jtag_TDI, jtag_TDO_data);

   	$display("[TB] %t - Halting the Core", $realtime);
    	debug_mode_if.halt_harts(jtag_TCK, jtag_TMS, jtag_TRSTn, jtag_TDI, jtag_TDO_data);
    

        $value$plusargs("binary_mem=%s", binary_mem);
        $display("Loading application to memory from %s", binary_mem);
        $readmemh(binary_mem, dut.i_sram.genblk1[0].genblk1.i_ram.Mem_DP);  

    
        // write dpc to addr_i so that we know where we resume
	$display("[TB] %t - Writing the boot address into dpc", $realtime);
        debug_mode_if.write_reg_abstract_cmd(riscv::CSR_DPC, BEGIN_MEM_INSTR, jtag_TCK, jtag_TMS, jtag_TRSTn, jtag_TDI, jtag_TDO_data);

    
        // we have set dpc and loaded the binary, we can go now
        $display("[TB] %t - Resuming the CORE", $realtime);
        debug_mode_if.resume_harts(jtag_TCK, jtag_TMS, jtag_TRSTn, jtag_TDI, jtag_TDO_data);

    end

endmodule
