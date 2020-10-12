# Getting started

To get more familiar with CVA6 architecture, documentation is available to this link:

https://cva6.readthedocs.io/en/latest/

Checkout the repository and initialize all submodules
```
$ git --recursive clone https://github.com/ThalesGroup/cva6-softcore-contest.git
```

 Coremark application has been customized for the contest, for using coremark application, run :

 
```
$ cd cva6-softcore-contest
$ git apply 0001-coremark-modification.patch
```

# Prerequisites


## RISCV tool chain setting up
The tool chain is available to this link: https://github.com/riscv/riscv-gnu-toolchain
At first, you have to get the sources of the RISCV gnu toolchain:
```
$ git clone --recursive https://github.com/riscv/riscv-gnu-toolchain
```
Next, you have to install all standard packages needed to build the toolchain depending on your linux distribution.
Before installing the tool chain, it is important to define the environment variable RISCV=”path where the tool chain will be installed”.
Then, you have to set up the compiler by running the following command:
```
$ ./configure --prefix=$RISCV --disable-linux --with-cmodel=medany --with-arch=rv32ima
$ make newlib 
```
When the installation is achieved, do not forget to add $RISCV/bin to your PATH.

## Questa tool
Questa Prime **version 10.7** has been used for simulations.

## Vitis/Vivado setting up
This section will be completed in a next release (the so-called "2<sup>nd</sup> kit" planned early December 2020).
For the contest, CVA6 processor will be implemented on Zybo 7-20 board from Digilent. This board consists of Zynq 7 FPGA from Xilinx. 
To do so, **Vitis 2020.1** environment from Xilinx need to be installed.

Furthermore, Digilent provides board files for each development board.

This files ease the creating of new projects with automated configuration of several complicated components such as Zynq Processing System and memory interfaces.

All guidelines to install **vitis 2020.1** and **Zybo 7-20** board files are explained to the following link:
https://reference.digilentinc.com/reference/programmable-logic/guides/installation

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
- Compile CVA6 architecture and testbench with Questa Sim tool.
- Compile the software application to be run on CVA6 with RISCV tool chain.
- Run the simulation.

Questa tool will open with wave window. Some signals will be displayed; you are free to add as much as signals you for the contest.

Moreover, all `printf` used into software application will be displayed into the **transcript** window of Questa Sim and save into **uart** file to the root directory.

> Simulation may take lot of time, so you need to be patient to have results.

CVA6 software environment is detailed into `sw/app` directory.

# Synthesis and place and route get started
You can perform synthesis and place and route of the CVA6 architecture.

In the first time, synthesis and place and route are carried in out of context mode, that means that the CVA6 architecture is synthetized in the FPGA fabric without consideration of the IOs constraints.

That allows to have an estimation of the logical resources used by the CVA6 in the FPGA fabric as well as the maximal frequency of CVA6 architecture.

These both metrics are majors for a computation architecture.

Command to run for synthesis and place and route in out of context mode:
```
$ make cva6_ooc CLK_PERIOD_NS=<period of the architecture in ns>
```
For example, if you want to clock the architecture to 50MHz, you have to run:
```
$ make cva6_ooc CLK_PERIOD_NS=20
```
By default, synthesis is performed in batch mode, however that is possible to run this command using the GUI of Vivado:
```
$ make cva6_ooc CLK_PERIOD_NS=20 BATCH_MODE=0
```
This command generates synthesis and place and route reports in **fpga/reports_cva6_ooc_synth** and **fpga/reports_cva6_ooc_impl**.


