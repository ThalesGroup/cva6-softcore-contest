// Copyright (c) 2020 Thales.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.
//
// Author: Sebastien Jacq Thales Research & Technology
// Date: 07/12/2020
//
// Additional contributions by:
//         Sebastien Jacq - sjthales on github.com
//
// Description: Zybo z7-20 FPGA platform level testbench module.
//
// =========================================================================== //
// Revisions  :
// Date        Version  Author       Description
// 2021-11-05  0.1      S.Jacq       Testbench to test Zybo z7-20 FPGA platform
// =========================================================================== //


`timescale 1ns/1ns


import ariane_pkg::*;
import jtag_pkg::*;


module tb_cva6_zybo_z7_20;

    jtag_pkg::debug_mode_if_t  debug_mode_if = new;

    localparam BEGIN_MEM_INSTR = 32'h80000080;

    localparam int unsigned CLOCK_PERIOD = 8ns;

    logic clk_i;
    logic rx;
    logic tx;
    logic rst_i;

    logic        jtag_TCK;
    logic        jtag_TMS;
    logic        jtag_TDI;
    logic        jtag_TRSTn;
    logic        jtag_TDO_data;
    logic        jtag_TDO_driven;

    logic        s_trstn = 1'b0;
    logic        s_tck   = 1'b0;
    logic        s_tdi   = 1'b0;
    logic        s_tms   = 1'b0;
    logic        s_tdo;

    longint unsigned cycles;
    longint unsigned max_cycles;

    logic [31:0]   gpr;

    string binary = "";



    cva6_zybo_z7_20 DUT(
        .clk_sys(clk_i),
        .cpu_reset       (rst_i),   
  
        // jtag
        .trst_n          (jtag_TRSTn),
        .tck             (jtag_TCK),
        .tms             (jtag_TMS),
        .tdi             (jtag_TDI),
        .tdo             (jtag_TDO_data),
  
        //uart
        .rx              (rx), 
        .tx              (tx) 
    ); 


    uart_bus #(
        .BAUD_RATE ( 115200),
        .PARITY_EN ( 0)
    ) i_uart_bus(
        .rx              (tx),
        .tx              (rx),  
        .rx_en (1'b1)
    );

    assign jtag_TCK = s_tck;
    assign jtag_TRSTn = s_trstn;
    assign jtag_TMS = s_tms;
    assign jtag_TDI = s_tdi;
    
    assign s_tdo = jtag_TDO_data;

    initial begin
        clk_i = 1'b0;
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
        rst_i = 1'b1;
        
        #200ns

        // testing on the jtag link
        s_trstn = 1'b0;
        #5000ns;

        jtag_pkg::jtag_reset(s_tck, s_tms, s_trstn, s_tdi);
        #5000ns;
        jtag_pkg::jtag_softreset(s_tck, s_tms, s_trstn, s_tdi);
        #5000ns;
    
        jtag_pkg::jtag_bypass_test(s_tck, s_tms, s_trstn, s_tdi, s_tdo);
        #5000ns;       
    
        jtag_pkg::jtag_get_idcode(s_tck, s_tms, s_trstn, s_tdi, s_tdo);
        #5000ns;

        rst_i = 1'b0;
        #10000ns;
        debug_mode_if.init_dmi_access(s_tck, s_tms, s_trstn, s_tdi);

        debug_mode_if.set_dmactive(1'b1, s_tck, s_tms, s_trstn, s_tdi, s_tdo);
    
        debug_mode_if.set_hartsel(FC_CORE_ID, s_tck, s_tms, s_trstn, s_tdi, s_tdo);

        $display("[TB] %t - Halting the Core", $realtime);
        debug_mode_if.halt_harts(s_tck, s_tms, s_trstn, s_tdi, s_tdo);
    
        debug_mode_if.test_read_sbcs(s_tck, s_tms, s_trstn, s_tdi, s_tdo);
   
        // write dpc to addr_i so that we know where we resume
         debug_mode_if.write_reg_abstract_cmd(riscv::CSR_DPC,  BEGIN_MEM_INSTR,
                                     s_tck, s_tms, s_trstn, s_tdi, s_tdo);

        // we have set dpc and loaded the binary, we can go now
        $display("[TB] %t - Resuming the CORE", $realtime);
        debug_mode_if.resume_harts(s_tck, s_tms, s_trstn, s_tdi, s_tdo);

    end

endmodule
