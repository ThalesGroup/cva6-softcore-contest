# Software stack
A set of software applications is available in `app` directory.

## Applications

These applications are used to give an estimation of the computation performance of the CVA6 architecture. The jury will rank the results based on the number of cycles needed to encode the 4 second audio clip in simulation.

**All applications must run correctly to validate your results in the contest.**

These software applications are compiled in baremetal using the **BSP (Board Support Package)** in the bsp directory.

- **Helloworld** : Minimal application printing a string on the UART, without printf.
- **Helloworld printf** : Same application using printf.
- **Coremark** : Complete benchmark for testing the computing power of a processor. It generates a score called Coremark.
- **Mnist** : Digit recognition application.
- **QOA encoder** : Application encoding a 4 second audio clip in QOA format. It is the application used for the contest.
- **QOA encoder 1s** : Same application on a 1 second audio clip, provided to speed up simulations.

The Makefile in app directory allows the compilation of these applications. It consists of several targets.
If you want to compile an application and generate an executable file, you need to go into **app** directory and run:
```
make ‘application’.riscv
```
That generates the `application.riscv` executable link file which can be run on CVA6.
For instance with Coremark application:
```
make coremark.riscv
```
Another target may be useful to debug software applications on CVA6, it allows disassembling of the executable file, and it generates all the assembly code of the application. To do so, you have to run:
```
make ‘application’.D
```
For Coremark application:
```
make coremark.D
```

Otherwise, you may use the simpler :
```
make ‘application’
```
This will build every targets : `.riscv`, `.mem`, `.D`...

To clean the **app** directory :
```
make clean
```

To build all targets of all apps :
```
make
```

## BSP (Board Support Package)
The **BSP** is a low-level software package that supports the hardware platform. It is located in the **bsp** directory and comprises three directories:
- **Config**: It contains the linker script and fpga_platform_config.h file which defines some constant relating to the FPGA platform.
- **Drivers**: it contains all peripheral driver. For now, there is only the UART driver.
- **Hal**: Hardware Abstract Layer contains the runtime system interrupt vectors, system calls.
