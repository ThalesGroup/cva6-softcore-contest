

connect -url tcp:127.0.0.1:3121
targets -set -nocase -filter {name =~"APU*"}
rst -system
after 3000
#targets -set -filter {jtag_cable_name =~ "Digilent Zybo Z7 210351AD67C0A" && level==0 && jtag_device_ctx=="jsn-Zybo Z7-210351AD67C0A-23727093-0"}
fpga -file cva6_fpga.runs/impl_1/cva6_zybo_z7_20.bit
#targets -set -nocase -filter {name =~"APU*"}
#loadhw -hw /home/sjacq/Work_dir/USE_CASE/2020/contest_softcore_cva6/migration2github/test/workspace/design_1_wrapper/export/design_1_wrapper/hw/design_1_wrapper.xsa -mem-ranges [list {0x40000000 0xbfffffff}] -regs
#configparams force-mem-access 1
targets -set -nocase -filter {name =~"APU*"}
source scripts/ps7_init.tcl
ps7_init
ps7_post_config

