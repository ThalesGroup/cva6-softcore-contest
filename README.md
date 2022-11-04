# Getting started

To get more familiar with CVA6 architecture, a partial documentation is available:

https://cva6.readthedocs.io/en/latest/

Checkout the repository and initialize all submodules:
```
$ git clone --recursive https://github.com/ThalesGroup/cva6-softcore-contest.git
```

Do not forget to check all the details of the contest in [Annonce RISC-V contest 2022-2023 v1.pdf](./Annonce%20RISC-V%20contest%202022-2023%20v1.pdf).

This repository contains the files needed for the 2022-2023 contest focusing on security. The 2020-2021 contest focusing on the performance can be retrieved in this repository under the cv32a6_contest_2020 GitHub tag. The 2021-2022 contest focusing on energy efficiency can be retrieved in this repository under the cv32a6_contest_2021 GitHub tag.

Thank you to Wilander and Nikiforakis for providing an open source intrusion prevention evaluator [RIPE](https://github.com/johnwilander/RIPE).

# Prerequisites

## Vitis/Vivado setting up

For the contest, the CVA6 processor will be implemented on Zybo Z7-20 board from Digilent. This board integrates a Zynq 7000 FPGA from Xilinx. 
To do so, **Vitis 2020.1** environment from Xilinx needs to be installed.

Furthermore, Digilent provides board files for each development board.

These files ease the creation of new projects with automated configuration of several complicated components such as Zynq Processing System and memory interfaces.

All guidelines to install **vitis 2020.1** and **Zybo Z7-20** board files are explained in
https://reference.digilentinc.com/reference/programmable-logic/guides/installation.

**Be careful about your linux distribution and the supported version of Vitis 2020.1 environment.**

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
$ git checkout aec5cca15b41d778fb85e95b38a9a552438fec6a
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
The file is also available here: https://github.com/riscv/riscv-openocd/blob/riscv/contrib/60-openocd.rules.
The particular entry about the HS2 cable is:
```
ATTRS{idVendor}=="0403", ATTRS{idProduct}=="6014", MODE="660", GROUP="plugdev", TAG+="uaccess"
```
Then either reboot your system or reload the udev configuration with:
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
# FPGA platform

A FPGA platform running **CV32A6** (CVA6 in 32b flavor) has been implemented on **Zybo Z7-20**

This platform includes a CV32A6 processor, a JTAG interface to run and debug software applications and a UART interface to display strings on hyperterminal.

The steps to run the RIPE application on CV32A6 FPGA platform are described below.

The JTAG-HS2 programming cable is initially a cable that allows programming of Xilinx FPGAs (bitstream loading) from a host PC.

In our case, we use this cable to program software applications on the CV32A6 instantiated in the FPGA through a PMOD connector.

## Get the Zybo ready

1. First, make sure the Digilent **JTAG-HS2 debug adapter** is properly connected to the **PMOD JE** connector and that the USBAUART adapter is properly connected to the **PMOD JB** connector of the Zybo Z7-20 board.
![alt text](./docs/pictures/20201204_150708.jpg)

2. Generate the bitstream of the FPGA platform:
```
$ make cva6_fpga
```

3. When the bitstream is generated, switch on Zybo board and run:
```
$ make program_cva6_fpga
```
When the bitstream is loaded, the green LED `done` lights up.
![alt text](./docs/pictures/20201204_160542.jpg)

4. Then, in a terminal, launch **OpenOCD**:
```
$ openocd -f fpga/openocd_digilent_hs2.cfg
```
If it is succesful, you should see something like:
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
5. Get a hyperterminal configured on /dev/ttyUSB0 11520-8-N-1

Now, the hardware is ready, the debugger is halting the processor and waiting for a gdb connection and the hyperterminal is connected to the UART output of the FPGA. We can now start the software.

## Get started with Zephyr in the docker image

### Installation

#### Building Developer Docker Image

The developer docker image can be built using the following command from the zephyr-docker folder:

```
docker build -f Dockerfile --build-arg UID=$(id -u) --build-arg GID=$(id -g) -t zephyr-build:v1 .
```

It can be used for building Zephyr samples and tests by mounting the Zephyr workspace into it:

```
docker run -ti -v `realpath workspace`:/workdir zephyr-build:v1
```

### Usage

#### Initialization of Zephyr

To initialize Zephyr environment with the Thales modified Zephyr:

```
cd /workdir
west init -m https://github.com/ThalesGroup/riscv-zephyr --mr main
west update
```

Thales modifications add CV32A6 support on Zybo board.

#### Building a sample application

Follow the steps below to build and run a sample application:

```
west build -p -b qemu_riscv32 /workdir/zephyr/samples/hello_world
west build -t run
```

You should now have a running hello world project on qemu_riscv32.

#### Building RIPE for the CV32A6 on ZYBO

The test is selected in the /workdir/ripe/src/ripe_attack_generator.c file with the following macro :
```
#define ATTACK_NR 1
```
By default its value is 1 but you should try to protect against as many scenario as possible.

Now that we have a working environment, we can build the RIPE attack.

```
west build -p -b cv32a6_zybo /workdir/ripe
```

#### Running the RIPE application on the CV32A6

You can launch the elf file located in build/zephyr/zephyr.elf with the gdb provided by zephyr-sdk.
```
/opt/toolchains/zephyr-sdk-0.15.1/riscv64-zephyr-elf/bin/riscv64-zephyr-elf-gdb /workdir/build/zephyr/zephyr.elf
```

You should see
```
GNU gdb (Zephyr SDK 0.15.1) 12.1
Copyright (C) 2022 Free Software Foundation, Inc.
License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>
This is free software: you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.
Type "show copying" and "show warranty" for details.
This GDB was configured as "--host=x86_64-build_pc-linux-gnu --target=riscv64-zephyr-elf".
Type "show configuration" for configuration details.
For bug reporting instructions, please see:
<https://github.com/zephyrproject-rtos/sdk-ng/issues>.
Find the GDB manual and other documentation resources online at:
    <http://www.gnu.org/software/gdb/documentation/>.

For help, type "help".
Type "apropos word" to search for commands related to "word"...
Reading symbols from build/zephyr/zephyr.elf...
```

The host is connecting to the hardware through OpenOCD and launching the gdbserver. You will need the name of the host in order to connect to it from inside the docker. Similar to this:
```
(gdb) target remote 172.18.0.1:3333
```
if it is successful, you should see the gdb connection in the host openocd:
```
Info : accepting 'gdb' connection on tcp/3333
```

load the elf file to CV32A6 FPGA platform:
```
(gdb) load
Loading section rom_start, size 0x18 lma 0x80000000
Loading section reset, size 0x4 lma 0x80000018
Loading section exceptions, size 0x1c8 lma 0x8000001c
Loading section text, size 0x72ec lma 0x800001e4
Loading section initlevel, size 0x28 lma 0x800074d0
Loading section devices, size 0x18 lma 0x800074f8
Loading section sw_isr_table, size 0x200 lma 0x80007510
Loading section device_handles, size 0x6 lma 0x80007710
Loading section rodata, size 0x1120 lma 0x80007718
Loading section datas, size 0x6c0 lma 0x8000b160
Loading section device_states, size 0x4 lma 0x8000b820
Loading section k_mutex_area, size 0x14 lma 0x8000b824
Start address 0x80000000, load size 36622
Transfer rate: 65 KB/sec, 2817 bytes/write.
```

At last you can run the RIPE application with command `c`:
```
(gdb) c
Continuing.
(gdb) 
```

On the host hyperterminal configured on /dev/ttyUSB0 11520-8-N-1, you should see:
```
*** Booting Zephyr OS build zephyr-v3.2.0-324-gf5d5bc39c3af  ***
RIPE is alive! cv32a6_zybo
RIPE parameters:
technique       direct
inject param    shellcode
code pointer    ret
location        stack
function        memcpy
----------------
Shellcode instructions:
lui t1,  0x80001                     80001337
addi t1, t1, 0xb1c                   b1c30313
jalr t1                              000300e7
----------------
target_addr == 0x8000afec
buffer == 0x8000aa70
payload size == 1409
bytes to pad: 1392

overflow_ptr: 0x8000aa70
payload: 7

Executing attack... success.
Code injection function reached.
exit
```
This result shows that the penetration test has succeeded.

