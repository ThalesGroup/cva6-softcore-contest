# Copyright (c) 2020 Thales.
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
# Description:    Script to generate bitstream of CVA6 architecture
#                 in Zybo 7-20 board
#
# =========================================================================== #
# Revisions  :
# Date        Version  Author       Description
# 2020-11-06  0.1      S.Jacq       Created
# =========================================================================== #
#set project compile_lib

#create_project $project . 
#-force -part $::env(XILINX_PART)
#set_property board_part $::env(XILINX_BOARD) [current_project]

#compile_simlib -simulator questa -simulator_exec_path {/opt/mentor/questa/2019.4_1/questasim/bin} -family zynq -language all -library all -dir {/home/sjacq/Work_dir/USE_CASE/2021/cva6_contest_2021_2022/cva6-softcore-contest_integration/fpga/lib_xilinx_questa} -force -verbose 

compile_simlib -simulator questa -simulator_exec_path $::env(QUESTA_BIN) -family zynq -language all -library all -dir $::env(LIB_XILINX_QUESTA_PATH) -force -verbose 
