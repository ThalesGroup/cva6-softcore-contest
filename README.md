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

And finally, do not forget to check all the details of the contest at [https://github.com/sjthales/cva6-softcore-contest/blob/master/Annonce RISC-V contest v4.pdf](<https://github.com/sjthales/cva6-softcore-contest/blob/master/Annonce RISC-V contest v4.pdf>).

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

To be able to run and debug software applications on CVA6, you need to install the OpenOCD tool.
OpenOCD is a free and open-source software distributed under the GPL-2.0 license.
It provides on-chip programming and debugging support with a layered architecture of JTAG interface and TAP support.

Global documentation on OpenOCD is available at https://github.com/ThalesGroup/pulpino-compliant-debug/tree/pulpino-dbg/doc/riscv-debug-notes/pdfs

These documents aim at providing help about OpenOCD and RISC-V debug.

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
- Launch the bootstrap script:
```
$ ./bootstrap
```
- Launch configure:
```
$ ./configure --enable-ftdi --prefix=<absolute path>/build --exec-prefix=<absolute path>/build
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
$ sudo cp <path to riscv-openocd>/build/share/openocd/contrib/60-openocd.rules /etc/udev/rules.d
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



# Simulation get started
When the development environment is set up, it is now possible to run a simulation.
Some software applications are available into the sw/app directory. Especially, there are benchmark applications such as Dhrystone and CoreMark and other test applications.

To simulate a software application on CVA6 processor, run the following command:
```
$ make sim APP=’application to run’
```
For instance, if you want to run the CoreMark application, you will have to run :
```
$ make sim APP=coremark
```
For instance, if you want to run Dhrystone application, you will have to run :
```
$ make sim APP=dhrystone

```
**This command:**
- Compiles CVA6 architecture and testbench with Questa Sim tool.
- Compiles the software application to be run on CVA6 with RISCV tool chain.
- Runs the simulation.

Questa tool will open with waveform window. Some signals will be displayed; you are free to add as many signals as you want.

Moreover, all `printf` used in software application will be displayed into the **transcript** window of Questa Sim and save into **uart** file to the root directory.

> Simulation may take lot of time, so you need to be patient to have results.

Simulation is programmed to run 10000000 cycles but the result is displayed before the end of simulation.

For Dhrystone application, at the end of the simulation, Dhrystone result is diplayed as following:
```
Dhrystones per Second: 
```
and for coremark application, result at the end of simulation is displayed as following:
```
CoreMark 1.0 :
```

CVA6 software environment is detailed into `sw/app` directory.

# Synthesis and place and route get started
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


# FPGA platform

A FPGA platform prototyping **CV32A6** (CVA6 in 32-bit flavor) has been implemented on **Zybo Z7-20** board.

This platform integrates a CV32A6 processor (clocked to 25MHz), a JTAG interface to run and debug software applications and a UART interface to display strings on a hyperterminal.

Below are described steps to run Coremark application on CV32A6 FPGA platform, steps are the same for Dhrystone application and other software applications.

The JTAG-HS2 programming cable is initially a cable that allows programming of Xilinx FPGAs (bitstream loading) from a host PC.

In our case, we use this cable to program software applications on the CV32A6 instantiated in the FPGA through a PMOD connector.


## Get started with Coremark application

1. First, make sure the Digilent **JTAG-HS2 debug adapter** is properly connected to the **PMOD JE** connector and that the USBUART adapter is properly connected to the **PMOD JB** connector of the Zybo Z7-20 board.
![alt text](https://github.com/sjthales/cva6-softcore-contest/blob/master/docs/pictures/20201204_150708.jpg)
2. Compile Coremark application in `sw/app`. Commands to compile Coremark application are described in `sw/app` directory.
3. Generate the bitstream of the FPGA platform. There are **two** FPGA platform, one using BRAM as main memory and another one using DDR conected to Zynq PS as main memory. Using the DDR allows savings of logic resources in FPGA fabric. You can choose the FPGA platform you want to implement :

If you want to implement the FPGA platform using BRAM, you have to run the following command: 
```
$ make cva6_fpga
```

If you want to implement the FPGA platform using DDR, you have to run the following command: 
```
$ make cva6_fpga_ddr
```
4. When the bitstream is generated, switch on Zybo board and run:
```
$ make program_cva6_fpga
```
When the bitstream is loaded, the green LED `done` lights up.
![alt text](https://github.com/sjthales/cva6-softcore-contest/blob/master/docs/pictures/20201204_160542.jpg)

5. Then, in a terminal, launch **OpenOCD**:
```
$ openocd -f fpga/openocd_digilent_hs2.cfg
```
If it is successful, you should see:
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
$ riscv32-unknown-elf-gdb sw/app/coremark.riscv
```
you must use the gdb from the RISC-V toolchain. If it is successful, you should see:
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
7. In **gdb**, you need to connect gdb to openocd:
```
(gdb) target remote :3333
```
if it is successful, you should see the gdb connection in **openocd**:
```
Info : accepting 'gdb' connection on tcp/3333
```
8. In **gdb**, load **coremark.riscv** to CV32A6 FPGA platform by the **load** command:
```
(gdb) load
Loading section .vectors, size 0x80 lma 0x80000000
Loading section .init, size 0x60 lma 0x80000080
Loading section .text, size 0x19010 lma 0x800000e0
Loading section .rodata, size 0x1520 lma 0x800190f0
Loading section .eh_frame, size 0x50 lma 0x8001a610
Loading section .init_array, size 0x4 lma 0x8001a660
Loading section .data, size 0x9d4 lma 0x8001a668
Loading section .sdata, size 0x40 lma 0x8001b040
Start address 0x80000080, load size 110712
Transfer rate: 63 KB/sec, 7908 bytes/write.
```

9. At last, in **gdb**, you can run the coremark application by command `c`:
```
(gdb) c
Continuing.
(gdb) 
```

10. On the hyperterminal configured on /dev/ttyUSB0 11520-8-N-1, you should see:
```
2K performance run parameters for coremark.

....

CoreMark 1.0 : [the CoreMark score
```
