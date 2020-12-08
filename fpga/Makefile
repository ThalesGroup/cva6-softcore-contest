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
# script Name:    Hardware architecture Makefile 
# Project Name:   CVA6 softcore
# Language:       Makefile
#
# Description:    Makefile to synthesize/place and route CVA6 architecture
#
# =========================================================================== #
# Revisions  :
# Date        Version  Author       Description
# 2020-10-06  0.1      S.Jacq       Created
# =========================================================================== #

VIVADO ?= vivado

work-dir := work-fpga
bit := $(work-dir)/cva6_fpga.bit

ip-dir := xilinx
ips := xlnx_blk_mem_gen.xci  \
       xlnx_axi_clock_converter.xci  \
       xlnx_axi_dwidth_converter_dm_master.xci \
       xlnx_axi_dwidth_converter_dm_slave.xci \
       xlnx_clk_gen.xci             

all: $(cva6_ooc)

cva6_ooc: 
ifeq ($(BATCH_MODE), 1)
	$(VIVADO) -mode batch -source  scripts/run_cva6_ooc.tcl
else
	$(VIVADO) -source scripts/run_cva6_ooc.tcl	
endif

cva6_fpga: $(ips)
ifeq ($(BATCH_MODE), 1)
	mkdir -p $(work-dir)
	$(VIVADO) -mode batch -source scripts/run_cva6_fpga.tcl
else
	$(VIVADO) -source scripts/run_cva6_fpga.tcl	
endif

program_cva6_fpga:
ifeq ($(BATCH_MODE), 1)
	$(VIVADO) -mode batch -source scripts/program_cva6_fpga.tcl
else
	$(VIVADO) -source scripts/program_cva6_fpga.tcl	
endif

get_hs2_sn:
	$(VIVADO) -mode batch -source scripts/get_hs2_sn.tcl




$(ips): %.xci :
	mkdir -p $(work-dir)
	@echo Generating $(@F)
	@cd $(ip-dir)/$(basename $(@F)) && make clean && make
	@cp $(ip-dir)/$(basename $(@F))/ip/$(@F) $@

clean:
	rm -rf 	*.log \
		*.jou \
		*.str \
		*.mif \
		*.xpr \
		*.xci \
		cva6_ooc.cache \
		cva6_ooc.hw \
		cva6_ooc.ip_user_files \
		cva6_ooc.sim \
		cva6_ooc.runs \
		cva6_ooc.hbs \
		cva6_fpga.cache \
		cva6_fpga.hw \
		cva6_fpga.ip_user_files \
		cva6_fpga.sim \
		cva6_fpga.runs \
		cva6_fpga.hbs \
		.Xil \
		reports_cva6_ooc_synth \
		reports_cva6_ooc_impl \
		reports_cva6_fpga_synth \
		reports_cva6_fpga_impl \
		$(work-dir)


.PHONY:
	clean
