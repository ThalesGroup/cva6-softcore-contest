# Getting started

To get more familiar with CVA6 architecture, a partial documentation is available:

https://cva6.readthedocs.io/en/latest/

Checkout the repository and initialize all submodules:
```
$ git --recursive clone https://github.com/ThalesGroup/cva6-softcore-contest.git
```

> As of October 12th, 2020, we are working hard to solve an alleged performance regression of CVA6 vs. an older versions. You'll be updated when it's solved.

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
```
Next, you have to install all standard packages needed to build the toolchain depending on your Linux distribution.
Before installing the tool chain, it is important to define the environment variable RISCV=”path where the tool chain will be installed”.
Then, you have to set up the compiler by running the following command:
```
$ ./configure --prefix=$RISCV --disable-linux --with-cmodel=medany --with-arch=rv32ima
$ make newlib 
```
When the installation is achieved, do not forget to add $RISCV/bin to your PATH.

## Questa tool
Questa Prime **version 10.7** has been used for simulations.
Other simulation tools and versions can be used but will receive no support from the organization team.

## Vitis/Vivado setting up
This section will be completed in a next release (planned early December 2020).
For the contest, the CVA6 processor will be implemented on Zybo Z7-20 board from Digilent. This board integrates a Zynq 7000 FPGA from Xilinx. 
To do so, **Vitis 2020.1** environment from Xilinx need to be installed.

Furthermore, Digilent provides board files for each development board.

This files ease the creation of new projects with automated configuration of several complicated components such as Zynq Processing System and memory interfaces.

All guidelines to install **vitis 2020.1** and **Zybo Z7-20** board files are explained to the following link:
https://reference.digilentinc.com/reference/programmable-logic/guides/installation

**be careful about your linux distribution and the supported version of Vitis 2020.1 environment**

If you have not yet done so, start provisioning the following:

| Reference	                 | URL                                                                             |	List price |	Remark                            |
| :------------------------- | :------------------------------------------------------------------------------ | ---------: | :-------------------------------- |
| Zybo Z7-20	                | https://store.digilentinc.com/zybo-z7-zynq-7000-arm-fpga-soc-development-board/ |    $299.00	| Zybo Z7-10 is too small for CVA6. |
| Pmod USBUART               |	https://store.digilentinc.com/pmod-usbuart-usb-to-uart-interface/               |      $9.99 |	Used for the console output       |
| JTAG-HS2 Programming Cable |	https://store.digilentinc.com/jtag-hs2-programming-cable/                       |     $59.00	|                                   |
| Connectors                 |	https://store.digilentinc.com/pmod-cable-kit-2x6-pin-and-2x6-pin-to-dual-6-pin-pmod-splitter-cable/ | $5.99 |	At least a 6-pin connector Pmod is necessary; other references may offer it. |


## Simulation get started
When the development environment is set up, it is now possible to run a simulation.
Some software applications are available into the sw/app directory. Especially, there are benchmark applications such as Dhrystone and Coremark and other test applications.

To simulate a software application on CVA6 processor, run the following command:
```
$ make sim APP=’application to run’
```
For instance, if you want to run Coremark application, you will have to run :
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


