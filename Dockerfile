# Copyright (c) 2023 Thales.
# 
# Copyright and related rights are licensed under the Apache
# License, Version 2.0 (the "License"); you may not use this file except in
# compliance with the License.  You may obtain a copy of the License at
# https://www.apache.org/licenses/LICENSE-2.0. Unless required by applicable law
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
# script Name:    Dockerfile
# Project Name:   cva6-softcore-contest
# Language:       
#
# Description:    This dokerfile aims at building a container image including 
#                 RISCV GCC13.1.0 and OpenOCD
#
# =========================================================================== #
# Revisions  :
# Date        Version  Author       Description
# 2023-11-22  0.1      S.Jacq       Created
# =========================================================================== #

FROM ubuntu:20.04


ARG UID=1000
ARG GID=1000


# Set default shell during Docker image build to bash
SHELL ["/bin/bash", "-c"]

# Set non-interactive frontend for apt-get to skip any user confirmations
ENV DEBIAN_FRONTEND=noninteractive



COPY ./util util

WORKDIR util

# Install base packages
RUN apt-get -y update && \
	apt-get -y upgrade && \
	apt-get install --no-install-recommends -y \
	ca-certificates \
		autoconf \
		automake \
		autotools-dev \
		curl \
		git \
		libmpc-dev \
		libmpfr-dev \
		libgmp-dev \
		gawk \
		build-essential \
		bison \
		flex \
		texinfo \
		gperf \
		libtool \
		bc \
		zlib1g-dev \
		libusb-1.0-0-dev \
		libftdi1-dev \
		srecord \
		sudo \
		texinfo \
		udev \
		locales \
		make \
		net-tools \
		ninja-build \
		openssh-client \
		pkg-config \
		g++ \
		gawk \
		gcc \
		python3-dev \
		python3-pip \
		python3-ply \
		python3-setuptools \
		python-is-python3 
		


# install openOCD
RUN git clone https://github.com/openocd-org/openocd && \
    cd openocd && \
    git checkout v0.11.0 && \
    mkdir build && \
    ./bootstrap && \
    ./configure --enable-ftdi --prefix=/util/riscv-openocd/build --exec-prefix=/util/riscv-openocd/build && \
    make && \
    make install

ENV PATH="$PATH:/util/riscv-openocd/build/bin"				
		
# Install rule for udev to access HS2 cable
RUN echo "ATTRS{idVendor}==\"0403\", ATTRS{idProduct}==\"6014\", MODE=\"660\", GROUP=\"plugdev\", TAG+=\"uaccess\"" > /etc/udev/rules.d/60-openocd.rules


# install RISCV toolchain
RUN export RISCV=riscv_toolchain && \
    cd gcc-toolchain-builder && \
    ls -al && \
    bash ./get-toolchain.sh && \
    bash ./build-toolchain.sh $RISCV


ENV PATH="$PATH:/util/gcc-toolchain-builder/riscv_toolchain/bin"


RUN mkdir /workdir
WORKDIR /workdir



# Create 'user' account
RUN groupadd -g $GID -o user

RUN useradd -u $UID -m -g user -G plugdev user \
	&& echo 'user ALL = NOPASSWD: ALL' > /etc/sudoers.d/user \
	&& chmod 0440 /etc/sudoers.d/user

USER user




