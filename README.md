# Getting started

To get more familiar with CVA6 architecture, a partial documentation is available:

https://cva6.readthedocs.io/en/latest/

Checkout the repository and initialize all submodules:
```
$ git clone --recursive https://github.com/ThalesGroup/cva6-softcore-contest.git
```

CoreMark application has been customized for the contest, for using CoreMark application, run:

 
```
$ cd cva6-softcore-contest
$ git apply 0001-coremark-modification.patch
```

And finally, do not forget to check all the details of the contest at [https://github.com/sjthales/cva6-softcore-contest/blob/master/Annonce RISC-V contest v4.pdf](<https://github.com/sjthales/cva6-softcore-contest/blob/master/Annonce RISC-V contest 2021-2022 v1.pdf>).

# Prerequisites


## RISC-V tool chain setting up
The tool chain is available to this link: https://github.com/riscv/riscv-gnu-toolchain
At first, you have to get the sources of the RISCV GNU toolchain:
```
$ git clone --recursive https://github.com/riscv/riscv-gnu-toolchain 
$ cd riscv-gnu-toolchain 
$ git checkout ed53ae7a71dfc6df1940c2255aea5bf542a9c422
```
Next, you have to install all standard packages needed to build the toolchain depending on your Linux distribution.
Before installing the tool chain, it is important to define the environment variable RISCV=”path where the tool chain will be installed”.
Then, you have to set up the compiler by running the following command:
```
$ export RISCV=/path/to/install/riscv/compilators
$ ./configure --prefix=$RISCV --disable-linux --with-cmodel=medany --with-arch=rv32ima
$ make newlib 
```
When the installation is achieved, do not forget to add $RISCV/bin to your PATH.
```
$ export PATH=$PATH:$RISCV/bin
```

## Questa tool
Questa Prime **version 10.7** has been used for simulations.
Other simulation tools and versions can be used but will receive no support from the organization team.

Performances **must** be measured using the Questa simulator.

## Vitis/Vivado setting up
This section will be completed in a next release (planned early December 2020).
For the contest, the CVA6 processor will be implemented on Zybo Z7-20 board from Digilent. This board integrates a Zynq 7000 FPGA from Xilinx. 
To do so, **Vitis 2020.1** environment from Xilinx need to be installed.

Furthermore, Digilent provides board files for each development board.

This files ease the creation of new projects with automated configuration of several complicated components such as Zynq Processing System and memory interfaces.

All guidelines to install **vitis 2020.1** and **Zybo Z7-20** board files are explained to the following link:
https://reference.digilentinc.com/reference/programmable-logic/guides/installation

**be careful about your linux distribution and the supported version of Vitis 2020.1 environment**


## Hardware 
If you have not yet done so, start provisioning the following:

| Reference	                 | URL                                                                             |	List price |	Remark                            |
| :------------------------- | :------------------------------------------------------------------------------ | ---------: | :-------------------------------- |
| Zybo Z7-20	                | https://store.digilentinc.com/zybo-z7-zynq-7000-arm-fpga-soc-development-board/ |    $299.00	| Zybo Z7-10 is too small for CVA6. |
| Pmod USBUART               |	https://store.digilentinc.com/pmod-usbuart-usb-to-uart-interface/               |      $9.99 |	Used for the console output       |
| JTAG-HS2 Programming Cable |	https://store.digilentinc.com/jtag-hs2-programming-cable/                       |     $59.00	|                                   |
| Connectors                 |	https://store.digilentinc.com/pmod-cable-kit-2x6-pin-and-2x6-pin-to-dual-6-pin-pmod-splitter-cable/ | $5.99 |	At least a 6-pin connector Pmod is necessary; other references may offer it. |


## OpenOCD

To be able to run and debug software applications on CVA6, you need to install OpenOCD tool.
OpenOCD is a free and open-source software distributed under the GPL-2.0 license.
It provides on-chip programming and debugging support with a layered architecture of JTAG interface and TAP support.

Global documentation on OpenOCD is available at https://github.com/ThalesGroup/pulpino-compliant-debug/tree/pulpino-dbg/doc/riscv-debug-notes/pdfs

Theses documents aim at providing help about OpenOCD and RISC-V debug.

Before setting up OpenOCD, other tools are needed:
- make
- libtool
- pkg-congfig > 0.23
- autoconf > 2.64
- automake > 1.14
- texinfo

On Ubuntu, ensure that everything is installed with:
```
$ sudo apt install make libtool pkg-config autoconf automake texinfo
```

Furthermore, you need to set up libusb and libftdi libraries.
On Ubuntu:
```
$ sudo apt install libusb-1.0-0-dev libftdi1-dev
```

Once all dependencies are installed, OpenOCD can be set up.
- Download sources:
```
$ git clone https://github.com/riscv/riscv-openocd
$ cd riscv-openocd
```
- Prepare a **build** directory:
```
$ mkdir build
```
- Launch the bootstrap scipt:
```
$ ./bootstrap
```
- Launch configure:
```
$ ./configure --enable-ftdi --prefix=build --exec-prefix=build
```
- Compile and install files:
```
$ make
$ make install
```
When the installation is achieved, do not forget to add riscv-openocd/build/bin to your PATH.
```
$ export PATH=$PATH:<path to riscv-openocd>/build/bin
```

## HS2 cable

It is necessary to add a udev rule to use the cable.
OpenOCD provides a file containing the rule we need. Copy it into /etc/udev/rules.d/
```
$ sudo cp <openocd>/contrib/60-openocd.rules /etc/udev/rules.d
```
The file is also available here: https://github.com/riscv/riscv-openocd/blob/riscv/contrib/60-openocd.rules
The particular entry about the HS2 cable is :
```
ATTRS{idVendor}=="0403", ATTRS{idProduct}=="6014", MODE="660", GROUP="plugdev", TAG+="uaccess"
```
Then either reboot your system or reload the udev configuration with :
```
$ sudo udevadm control --reload
```

To check if the cable is recognized, run lsusb. There should be a line like this:
```
$ lsusb
```
```
Bus 005 Device 003: ID 0403:6014 Future Technology Devices International, Ltd FT232HSingle HS USB-UART/FIFO IC
```
# Contest

## Xilinx libraries compilation
Some Xilinx are needed in order to simulate xilinx IP with QuestaSim.
Therefore, before running a simulation, Xilinx libraries have to be compiled, to do so, run the command:
```
$ make compile_xilinx_lib
```
That will create a **fpga/lib_xilinx_questa** subdirectory. This command is to be launched only once.


## Behavioral simulation get started
When the development environment is set up, it is now possible to run a behavioral simulation.
Some software applications are available into the sw/app directory. Especially, Mnist application used for the contest is available as well as others tests applications.
A description of the Mnist application is available in the **sw/app/mnist** subdirectory.

To simulate Mnist software application on CV32A6 processor, run the following command: 
```
$ make cva6_sim
```

**This command:**
- Compiles CVA6 architecture and testbench with Questa Sim tool.
- Compiles the software application to be run on CVA6 with RISCV tool chain.
- Launches the simulation.

Questa tool will open with waveform window. Some signals will be displayed; you are free to add as many signals as you want.

Moreover, all `printf` used in software application will be displayed into the **transcript** window of Questa Sim and save into **uart** file to the root directory.

At the end of the Mnist application simulation, results ar deplayed in the transcript as following:
```
# [UART]: Expected  = 4                                                                                                                                                                                                                                                   
# [UART]: Predicted = 4                                                                                                                                                                                                                                                   
# [UART]: Result : 1/1                                                                                                                                                                                                                                                    
# [UART]: image env0003: 1730550 instructions                                                                                                                                                                                                                             
# [UART]: image env0003: 2129251 cycles  
```
> Simulation may take lot of time, so you need to be patient to have results. 

Results are displayed after 100msof running the Mnist application.

Another important point, in the context of the competition, only the image of a 4 is tested by the Mnist algorithm in order to reduce simulation times. 

CVA6 software environment is detailed into `sw/app` directory.

## Post-implementation simulation get started
To efficiently estimate the energy consumed by the Mnist application, the post-implementation simulation of the application must be run.
To do this, you have to run the following command:  
```
$ make cva6_sim_routed
```

**This command:**
- Compiles the software application to be run on CVA6 with RISCV tool chain.
- Run synthesis and implementation of CV32A6 FPGA platform, Mnist are initialized into main memory.
- Compiles CVA6 architecture and testbench with Questa Sim tool.
- Run the simulation 100ms.
- Generate **fpga/work-sim/routed.saif** file to estimate power needed. 

As for behavioral simulation, results ar deplayed in the transcript as following:
```
# [UART]: Expected  = 4                                                                                                                                                                                                                                                   
# [UART]: Predicted = 4                                                                                                                                                                                                                                                   
# [UART]: Result : 1/1                                                                                                                                                                                                                                                    
# [UART]: image env0003: 1730550 instructions                                                                                                                                                                                                                             
# [UART]: image env0003: 2129251 cycles  
```
> Simulation may take lot of time (many hours), so you need to be patient to have results.

## Power analysis get started
Once route.saif file is generated, Xilinx power analysis suite can be lauched to estimate the energy of the Mnist application.

to do so, run the following command:
```
$ make sim cva6_power_analysis
```
**This command:**
- Open Xilinx power analysis suite for mnist application.
- Generates **fpga/work-sim/power_routed_mnist.txt** file.

As part of the competition, we want to increase the energy efficiency of the Mnist application.

Below, please find an excerpt from the power report generated by Xilinx power analysis suite.

Power is made up of two components:
- A static part at **0.113 W**
- A dynamic part at **0.152 W**

The total power is the sum of these two components: **0.265 W** 
```
+--------------------------+----------------------+
| Total On-Chip Power (W)  | 0.265                |
| Design Power Budget (W)  | Unspecified*         |
| Power Budget Margin (W)  | NA                   |
| Dynamic (W)              | 0.152                |
| Device Static (W)        | 0.113                |
| Effective TJA (C/W)      | 11.5                 |
| Max Ambient (C)          | 81.9                 |
| Junction Temperature (C) | 28.1                 |
| Confidence Level         | Medium               |
| Setting File             | ---                  |
| Simulation Activity File | work-sim/routed.saif |
| Design Nets Matched      | 89%   (59430/66741)  |
+--------------------------+----------------------+
```
From the estimated power, the energy consumption can be calculated in Joule.
to do so:

**Energy (J) = Power (W) \* Execution time of one frame (s)**

**Energy (J) = Power (W) \* Number of cycles executed for one frame \* Period (s)**

Reference energy for one frame:

**Energy (J) = 0.265 W \* 2129251 \* 40 \* 10power(-9)= 0.02257 J = 22.57 mJ**

The reference architecture consumes **22.57 mJ**.

The dynamic component can be distributed hierarchically in the architecture. Below is another excerpt from the power report:
```
+-----------------------------+-----------+
| Name                        | Power (W) |
+-----------------------------+-----------+
| cva6_zybo_z7_20             |     0.152 |
|   i_ariane                  |     0.036 |
|     ex_stage_i              |     0.002 |
|       lsu_i                 |     0.001 |
|     i_cache_subsystem       |     0.016 |
|       i_wt_dcache           |     0.006 |
|       i_wt_icache           |     0.009 |
|     i_frontend              |     0.005 |
|       i_btb                 |     0.001 |
|       i_instr_queue         |     0.002 |
|     id_stage_i              |     0.001 |
|     issue_stage_i           |     0.011 |
|       i_issue_read_operands |     0.005 |
|       i_scoreboard          |     0.006 |
|   i_ariane_peripherals      |     0.002 |
|   i_axi_xbar                |     0.005 |
|   i_xlnx_clk_gen            |     0.107 |
|     inst                    |     0.107 |
+-----------------------------+-----------+
```
> Power < 1mW i not displayed.

The values extracted from the power report are to be considered as a reference, these values must be found by default.

A document explaining how to interprate the power analysis report will be delivered later.



## Synthesis and place and route get started
You can perform synthesis and place and route of the CVA6 architecture.

In the first time, synthesis and place and route are carried in "out of context" mode, that means that the CVA6 architecture is synthetized in the FPGA fabric without consideration of the external IOs constraints.

That allows to have an estimation of the logical resources used by the CVA6 in the FPGA fabric as well as the maximal frequency of CVA6 architecture. They are both major metrics for a computation architecture.

Command to run synthesis and place & route in "out of context" mode:
```
$ make cva6_ooc CLK_PERIOD_NS=<period of the architecture in ns>
```
For example, if you want to clock the architecture to 50 MHz, you have to run:
```
$ make cva6_ooc CLK_PERIOD_NS=20
```
By default, synthesis is performed in batch mode, however it is possible to run this command using Vivado GUI:
```
$ make cva6_ooc CLK_PERIOD_NS=20 BATCH_MODE=0
```
This command generates synthesis and place and route reports in **fpga/reports_cva6_ooc_synth** and **fpga/reports_cva6_ooc_impl**.


## FPGA emulation

A FPGA platform emulating **CV32A6** (CVA6 in 32b flavor) has been implemented on **Zybo Z7-20** board.

This platform consists of a CV32A6 processor, a JTAG interface to run and debug software applications and a UART interface to display strings on hyperterminal.

Below is described steps to run Coremark application on CV32A6 FPGA platform, steps are the same for Dhrystone application and others software applications.

## Get started with Mnist application on Zybo

1. First, make sure the digilent **JTAG-HS2 debug adapter** is properly connected to the **PMOD JE** connector and that the USBAUART adapter is properly connected to the **PMOD JB** connector of the Zybo Z7-20 board.
![alt text](https://github.com/sjthales/cva6-softcore-contest/blob/master/docs/pictures/20201204_150708.jpg)
2. compile coremark application in `sw/app`
3. Generate the bitstream of the FPGA platform:
```
$ make cva6_fpga
```
4. When bistream is generated, switch on Zybo board and run:
```
$ make program_cva6_fpga
```
When the bitstream is loaded, the green LED `done` lights up.
![alt text](https://github.com/sjthales/cva6-softcore-contest/blob/master/docs/pictures/20201204_160542.jpg)
5. then, in a terminal, launch **OpenOCD**:
```
$ openocd -f fpga/openocd_digilent_hs2.cfg
```
If it is succesful, you should see something like that:
```
Open On-Chip Debugger 0.10.0+dev-00832-gaec5cca (2019-12-10-14:21)
Licensed under GNU GPL v2
For bug reports, read
    http://openocd.org/doc/doxygen/bugs.html
Info : auto-selecting first available session transport "jtag". To override use 'transport select <transport>'.
Info : clock speed 1000 kHz
Info : JTAG tap: riscv.cpu tap/device found: 0x249511c3 (mfg: 0x0e1 (Wintec Industries), part: 0x4951, ver: 0x2)
Info : datacount=2 progbufsize=8
Info : Examined RISC-V core; found 1 harts
Info :  hart 0: XLEN=32, misa=0x40141105
Info : Listening on port 3333 for gdb connections
Ready for Remote Connections
Info : Listening on port 6666 for tcl connections
Info : Listening on port 4444 for telnet connections

```
6. In separate terminal, launch **gdb**:
```
$ riscv32-unknown-elf-gdb sw/app/mnist.riscv
```
you must use gdb of the RISC-V toolchain. If it is succesful, you should see:
```
GNU gdb (GDB) 9.1
Copyright (C) 2020 Free Software Foundation, Inc.
License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>
This is free software: you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.
Type "show copying" and "show warranty" for details.
This GDB was configured as "--host=x86_64-pc-linux-gnu --target=riscv32-unknown-elf".
Type "show configuration" for configuration details.
For bug reporting instructions, please see:
<http://www.gnu.org/software/gdb/bugs/>.
Find the GDB manual and other documentation resources online at:
    <http://www.gnu.org/software/gdb/documentation/>.

For help, type "help".
Type "apropos word" to search for commands related to "word"...
Reading symbols from sw/app/coremark.riscv...
(gdb) 
```
7. In gdb, you need to connect gdb to openocd:
```
(gdb) target remote :3333
```
if it is successful, you should see the gdb connection in openocd:
```
Info : accepting 'gdb' connection on tcp/3333
```
8. In gdb, load **mnist.riscv** to CV32A6 FPGA platform:
```
(gdb) load
Loading section .vectors, size 0x80 lma 0x80000000
Loading section .init, size 0x60 lma 0x80000080
Loading section .text, size 0x16044 lma 0x800000e0
Loading section .rodata, size 0x122a4 lma 0x80016130
Loading section .eh_frame, size 0x50 lma 0x800283d4
Loading section .init_array, size 0x4 lma 0x80028424
Loading section .data, size 0xc1c lma 0x80028428
Loading section .sdata, size 0x2c lma 0x80029048
Start address 0x80000080, load size 168036
Transfer rate: 61 KB/sec, 9884 bytes/write.
```

9. At last, in gdb, you can run the coremark application by command `c`:
```
(gdb) c
Continuing.
(gdb) 
```

10. On hyperterminal configured on /dev/ttyUSB0 11520-8-N-1, you should see:
```
Expected  = 4                                                                                                                                                                                                                                                   
Predicted = 4                                                                                                                                                                                                                                                   
Result : 1/1                                                                                                                                                                                                                                                    
image env0003: 1730550 instructions                                                                                                                                                                                                                             
image env0003: 2129251 cycles  
```

