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

| Reference	                 | URL                                                                             |	Remark                            |
| :------------------------- | :------------------------------------------------------------------------------ | :-------------------------------- |
| Zybo Z7-20	                | https://store.digilentinc.com/zybo-z7-zynq-7000-arm-fpga-soc-development-board/ | Zybo Z7-10 is too small for CVA6. |
| Pmod USBUART               |	https://store.digilentinc.com/pmod-usbuart-usb-to-uart-interface/               |	Used for the console output       |
| JTAG-HS2 Programming Cable |	https://store.digilentinc.com/jtag-hs2-programming-cable/                       |                                   |
| Connectors                 |	https://store.digilentinc.com/pmod-cable-kit-2x6-pin-and-2x6-pin-to-dual-6-pin-pmod-splitter-cable/ |	At least a 6-pin connector Pmod is necessary; other references may offer it. |

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

4. Get a hyperterminal configured on /dev/ttyUSB0 115200-8-N-1

Now, the hardware is ready and the hyperterminal is connected to the UART output of the FPGA. We can now start the software.

## Get started with Zephyr in the docker image

### Installation

#### Building Developer Docker Image

The developer docker image can be built using the following command from the zephyr-docker folder:

```
cd zephyr-docker
docker build -f Dockerfile --build-arg UID=$(id -u) --build-arg GID=$(id -g) -t zephyr-build:v1 .
```

It can be used for building Zephyr samples and tests by mounting the Zephyr workspace into it:

```
docker run -ti --privileged -v `realpath workspace`:/workdir zephyr-build:v1
```

All the following commands should be run from the docker.

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

You can launch the elf file located in build/zephyr/zephyr.elf with the tools provided by zephyr-sdk.
```
west debug
```

You should see
```
user@62813f8ca741:/workdir$ west debug
-- west debug: rebuilding
ninja: no work to do.
-- west debug: using runner openocd
-- runners.openocd: OpenOCD GDB server running on port 3333; no thread info available
Open On-Chip Debugger 0.11.0+dev-00725-gc5c47943d-dirty (2022-10-03-06:14)
Licensed under GNU GPL v2
For bug reports, read
        http://openocd.org/doc/doxygen/bugs.html
Info : auto-selecting first available session transport "jtag". To override use 'transport select <transport>'.
Warn : `riscv set_prefer_sba` is deprecated. Please use `riscv set_mem_access` instead.
Ready for Remote Connections
Info : clock speed 1000 kHz
Info : JTAG tap: riscv.cpu tap/device found: 0x249511c3 (mfg: 0x0e1 (Wintec Industries), part: 0x4951, ver: 0x2)
Info : datacount=2 progbufsize=8
Info : Examined RISC-V core; found 1 harts
Info :  hart 0: XLEN=32, misa=0x40141105
Info : starting gdb server for riscv.cpu on 3333
Info : Listening on port 3333 for gdb connections
    TargetName         Type       Endian TapName            State
--  ------------------ ---------- ------ ------------------ ------------
 0* riscv.cpu          riscv      little riscv.cpu          halted

Info : Listening on port 6333 for tcl connections
Info : Listening on port 4444 for telnet connections
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
Reading symbols from /workdir/build/zephyr/zephyr.elf...
Remote debugging using :3333
Info : accepting 'gdb' connection on tcp/3333
_exit (status=<optimized out>) at /workdir/zephyr/lib/libc/newlib/libc-hooks.c:281
281             while (1) {
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
Transfer rate: 63 KB/sec, 2817 bytes/write.
```

You can then run the RIPE application with command `c`:
```
(gdb) c
Continuing.
```

On the host hyperterminal you should see:
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

#### Building and executing the perf_baseline test application

The perf_baseline test application is measuring performance of the HW and SW on the FPGA by performing multiple compute, stack access and heap manipulations. This application is generated similarly than RIPE:

```
west build -p -b cv32a6_zybo /workdir/perf_baseline/
```
This step should give you the memory size of the application as follow :
```
Memory region         Used Size  Region Size  %age Used
             RAM:       61936 B         1 GB      0.01%
        IDT_LIST:          0 GB         2 KB      0.00%
```

The execution is also similar:
```
west debug
```

On the hyperterminal, you should have the output :
```
*** Booting Zephyr OS build zephyr-v3.2.0-327-g869365ab012b  ***
Begining of execution with depth 12, call number 50, seed value 63728127.000000
SUCCESS: computed value 868200.000000 - duration: 25.300611 sec 632515274 cycles
```

Your execution duration can be a little different than our, but the computed value should be the same.
