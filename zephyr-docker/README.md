# Zephyr Docker Images

This repository contains a Dockerfile for the Thales 2022 Contest

## Developer Docker Image

### Overview

This images include the [Zephyr SDK](https://github.com/zephyrproject-rtos/sdk-ng), which supports
building most Zephyr targets.

### Installation

#### Building Developer Docker Image

The developer docker image can be built using the following command:

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

Now that we have a working environment, we can build the RIPE attack.

```
west build -p -b cv32a6_zybo /workdir/ripe
```

Now you can launch the elf file located in build/zephyr/zephyr.elf

