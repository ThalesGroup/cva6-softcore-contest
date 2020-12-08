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
// 2020-12-07  0.1      S.Jacq       Testbench to test Zybo z7-20 FPGA platform
// =========================================================================== //


`timescale 1ns/1ps


import ariane_pkg::*;
import jtag_pkg::*;


`define EXIT_SUCCESS  0
`define EXIT_FAIL     1
`define EXIT_ERROR   -1


module tb_cva6_zybo_z7_20;


// enable Debug Module Tests
parameter ENABLE_DM_TESTS = 0;



// contains the program code
string stimuli_file;

/* simulation variables & flags */


int                   num_stim;
logic [95:0]          stimuli  [100000:0];                // array for the stimulus vectors

logic                 dev_dpi_en = 0;
logic [255:0][31:0]   jtag_data;



//jtag_pkg::test_mode_if_t   test_mode_if = new;
jtag_pkg::debug_mode_if_t  debug_mode_if = new;
//pulp_tap_pkg::pulp_tap_if_soc_t pulp_tap = new;

logic [8:0] jtag_conf_reg, jtag_conf_rego; //22bits but actually only the last 9bits are used
localparam BEGIN_MEM_INSTR = 32'h80000080;

int                   exit_status = `EXIT_ERROR;


//    static uvm_cmdline_processor uvcl = uvm_cmdline_processor::get_inst();

    localparam int unsigned CLOCK_PERIOD = 8ns;
    // toggle with RTC period
//    localparam int unsigned RTC_CLOCK_PERIOD = 30.517us;

    localparam NUM_WORDS = 2**25;
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


uart_bus
  #(
    .BAUD_RATE ( 115200),
    .PARITY_EN ( 0)
    ) i_uart_bus
  (
   
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
       
        // read in the stimuli vectors  == address_value
        if ($value$plusargs("stimuli=%s", stimuli_file)) begin
            $display("Loading custom stimuli from %s", stimuli_file);
	    $readmemh(stimuli_file, stimuli);
        end else begin
	    $display("Loading default stimuli");
	    //$readmemh("/home/sjacq/Work_dir/USE_CASE/2020/ohg/test_ariane/bug_performance_cva6/sw/app/dhrystone.stim.txt", stimuli);
	    $readmemh("/home/sjacq/Work_dir/USE_CASE/2020/contest_softcore_cva6/cva6-softcore-contest_zybo/fpga/sw_debug/app/helloworld.stim.txt", stimuli);
        end

        // before starting the actual boot procedure we do some light
        // testing on the jtag link
        jtag_pkg::jtag_reset(s_tck, s_tms, s_trstn, s_tdi);
        jtag_pkg::jtag_softreset(s_tck, s_tms, s_trstn, s_tdi);
        #5us;
    
        jtag_pkg::jtag_bypass_test(s_tck, s_tms, s_trstn, s_tdi, s_tdo);
        #5us;
    
        jtag_pkg::jtag_get_idcode(s_tck, s_tms, s_trstn, s_tdi, s_tdo);
        #5us;

        rst_i = 1'b0;
        #100us;
        debug_mode_if.init_dmi_access(s_tck, s_tms, s_trstn, s_tdi);

        debug_mode_if.set_dmactive(1'b1, s_tck, s_tms, s_trstn, s_tdi, s_tdo);
    
        debug_mode_if.set_hartsel(FC_CORE_ID, s_tck, s_tms, s_trstn, s_tdi, s_tdo);

        $display("[TB] %t - Halting the Core", $realtime);
        debug_mode_if.halt_harts(s_tck, s_tms, s_trstn, s_tdi, s_tdo);
    
        $display("[TB] %t - reading gpr 0x1000 ", $realtime);
        debug_mode_if.read_reg_abstract_cmd(16'h1000, gpr, s_tck, s_tms, s_trstn, s_tdi, s_tdo);

        $display("[TB] %t - reading gpr 0x1001 ", $realtime);
        debug_mode_if.read_reg_abstract_cmd(16'h1001, gpr, s_tck, s_tms, s_trstn, s_tdi, s_tdo);


       debug_mode_if.test_read_sbcs(s_tck, s_tms, s_trstn, s_tdi, s_tdo);
    
        $display("[TB] %t - Loading L2", $realtime);

        // use debug module to load binary
        debug_mode_if.load_L2_ini(num_stim, stimuli, s_tck, s_tms, s_trstn, s_tdi, s_tdo);

   
        // write dpc to addr_i so that we know where we resume
         debug_mode_if.write_reg_abstract_cmd(riscv::CSR_DPC,  BEGIN_MEM_INSTR,
                                     s_tck, s_tms, s_trstn, s_tdi, s_tdo);

        // we have set dpc and loaded the binary, we can go now
        $display("[TB] %t - Resuming the CORE", $realtime);
        debug_mode_if.resume_harts(s_tck, s_tms, s_trstn, s_tdi, s_tdo);

        #50000us;
        // enable sb access for subsequent readMem calls
        debug_mode_if.set_sbreadonaddr(1'b1, s_tck, s_tms, s_trstn, s_tdi, s_tdo);
    
        // wait for end of computation signal
        $display("[TB] %t - Waiting for end of computation", $realtime);
    
        jtag_data[0] = 0;
        while(jtag_data[0][31] == 0) begin
            debug_mode_if.readMem(32'h1A1040A0, jtag_data[0], s_tck, s_tms, s_trstn, s_tdi, s_tdo);
            #50us;
        end
    
        if (jtag_data[0][30:0] == 0)
            exit_status = `EXIT_SUCCESS;
        else
            exit_status = `EXIT_FAIL;

        $display("[TB] %t - Received status core: 0x%h", $realtime, jtag_data[0][30:0]);
    
        $stop;

    end

endmodule
