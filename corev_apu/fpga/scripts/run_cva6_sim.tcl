# Copyright (c) 2021 Thales.
# 
# Copyright and related rights are licensed under the Solderpad
# License, Version 2.0 (the "License"); you may not use this file except in
# compliance with the License.  You may obtain a copy of the License at
# http://solderpad.org/licenses/SHL-2.0/ Unless required by applicable law
# or agreed to in writing, software, hardware and materials distributed under
# this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
# CONDITIONS OF ANY KIND, either express or implied. See the License for the
# specific language governing permissions and limitations under the License.
#
# Author:         Sebastien Jacq - sjthales on github.com

#
# Additional contributions by:
#
#
# script Name:    run_cva6_sim
# Project Name:   CVA6 softcore
# Language:       tcl
#
# Description:    Script to run place and route implementation of CV32A6 FPGA 
#                 platform and which launches post-implementation simulation 
#                 of the software application on Questa.
#
# =========================================================================== #
# Revisions  :
# Date        Version  Author       Description
# 2021-11-03  0.1      S.Jacq       Created
# =========================================================================== #
set project cva6_sim

create_project $project . -force -part $::env(XILINX_PART)
set_property board_part $::env(XILINX_BOARD) [current_project]

if {$::env(SIM)} {
    puts "Simulation behavioral"
} else {
    puts "Simulation routed"
}

set_property target_simulator Questa [current_project]
set_property compxlib.questa_compiled_library_dir $::env(LIB_XILINX_QUESTA_PATH) [current_project]

# set number of threads to 8 (maximum, unfortunately)
set_param general.maxThreads 8

set_msg_config -id {[Synth 8-5858]} -new_severity "info"

set_msg_config -id {[Synth 8-4480]} -limit 1000

add_files -fileset constrs_1 -norecurse constraints/zybo_z7_20.xdc

read_ip xilinx/xlnx_processing_system7/ip/xlnx_processing_system7.xci
read_ip xilinx/xlnx_blk_mem_gen/ip/xlnx_blk_mem_gen.xci
read_ip xilinx/xlnx_axi_clock_converter/ip/xlnx_axi_clock_converter.xci
read_ip xilinx/xlnx_axi_dwidth_converter_dm_slave/ip/xlnx_axi_dwidth_converter_dm_slave.xci
read_ip xilinx/xlnx_axi_dwidth_converter_dm_master/ip/xlnx_axi_dwidth_converter_dm_master.xci

read_ip xilinx/xlnx_clk_gen/ip/xlnx_clk_gen.xci

set_property include_dirs { "src/axi_sd_bridge/include" "../src/common_cells/include" } [current_fileset]

source scripts/add_sources.tcl

set_property top cva6_zybo_z7_20 [current_fileset]

read_verilog -sv {src/zybo-z7-20.svh  ../src/common_cells/include/common_cells/registers.svh}
set file "src/zybo-z7-20.svh"

set registers "../src/common_cells/include/common_cells/registers.svh"

set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file" "$registers"]]
set_property -dict { file_type {Verilog Header} is_global_include 1} -objects $file_obj

update_compile_order -fileset sources_1

add_files -fileset constrs_1 -norecurse constraints/cva6_fpga.xdc

synth_design -verilog_define BRAM=BRAM -rtl -name rtl_1

set_property verilog_define WT_DCACHE=1 [get_filesets sim_1]

set_property top tb_cva6_zybo_z7_20 [get_filesets sim_1]
update_compile_order -fileset sim_1



if {$::env(SIM)} {
   puts "Behavioral simulation"
   reset_simulation -simset sim_1 
   launch_simulation
   
} else {
    puts "Post implementation simulation"
    launch_runs synth_1
    wait_on_run synth_1
    open_run synth_1
    
    # set for RuntimeOptimized implementation
    set_property "steps.place_design.args.directive" "RuntimeOptimized" [get_runs impl_1]
    set_property "steps.route_design.args.directive" "RuntimeOptimized" [get_runs impl_1]

    launch_runs impl_1
    wait_on_run impl_1
    open_run impl_1
    
    # reports
    exec mkdir -p reports_cva6_sim_impl/
    exec rm -rf reports_cva6_sim_impl/*
    check_timing                                                              -file reports_cva6_sim_impl/${project}.check_timing.rpt
    report_timing -max_paths 100 -nworst 100 -delay_type max -sort_by slack   -file reports_cva6_sim_impl/${project}.timing_WORST_100.rpt
    report_timing -nworst 1 -delay_type max -sort_by group                    -file reports_cva6_sim_impl/${project}.timing.rpt
    report_utilization -hierarchical                                          -file reports_cva6_sim_impl/${project}.utilization.rpt
    
    set_property -name {questa.simulate.custom_udo} -value {../../../../../scripts/sim_routed.udo} -objects [get_filesets sim_1]

    reset_simulation -simset sim_1 -mode post-implementation -type functional

    launch_simulation -mode post-implementation -type functional
}
