# Copyright (c) 2025 Thales.

# Copyright and related rights are licensed under the Apache
# License, Version 2.0 (the "License"); you may not use this file except in
# compliance with the License.  You may obtain a copy of the License at
# https://www.apache.org/licenses/LICENSE-2.0. Unless required by applicable law
# or agreed to in writing, software, hardware and materials distributed under
# this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
# CONDITIONS OF ANY KIND, either express or implied. See the License for the
# specific language governing permissions and limitations under the License.

# Author:         Julien Mallet -  J-Mallet on github.com

# Description:    FFT running on a predefined signal with predefined twiddles.

# ===========================================================================
# Revisions  :
# Date        Version  Author		Description
# 2025-10-06  0.1      J.Mallet 	Created
# ===========================================================================

FROM ubuntu:22.04

ARG UID=1000
ARG GID=1000

SHELL ["/bin/bash", "-c"]
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y  \
	ca-certificates curl git build-essential \
	autoconf automake autotools-dev libtool usbutils \
	libusb-1.0-0-dev libftdi1-dev libc6-dev \
	libmpc-dev libmpfr-dev libgmp-dev gawk bison flex gperf \
	texinfo zlib1g-dev pkg-config ninja-build bc \
	python3 python3-pip python3-dev python3-setuptools python3-ply \
	openssh-client sudo make net-tools locales vim nano\
	&& rm -rf /var/lib/apt/lists/*

RUN locale-gen en_US.UTF-8 && update-locale LANG=en_US.UTF-8
ENV LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8


WORKDIR /util

COPY util .

RUN git clone --branch v0.12.0 --depth 1 https://github.com/openocd-org/openocd && \
	cd openocd && \
	./bootstrap && \
	./configure --enable-ftdi --prefix=/util/riscv-openocd/build --exec-prefix=/util/riscv-openocd/build && \
	make -j"$(nproc)" && make install && \
	cd .. && rm -rf openocd
ENV PATH="/util/riscv-openocd/build/bin:${PATH}"

RUN mkdir -p /etc/udev/rules.d && \
	echo "ATTRS{idVendor}==\"0403\", ATTRS{idProduct}==\"6014\", MODE=\"660\", GROUP=\"plugdev\", TAG+=\"uaccess\"" > /etc/udev/rules.d/60-openocd.rules


#RUN cd gcc-toolchain-builder && \
#	bash ./get-toolchain.sh && \
#	bash ./build-toolchain.sh riscv_toolchain
#ENV PATH="/util/gcc-toolchain-builder/riscv_toolchain/bin:${PATH}"


RUN groupadd -g "${GID}" user || true && \
	getent group plugdev >/dev/null || groupadd -r plugdev && \
	useradd -u "${UID}" -m -g user -G plugdev -s /bin/bash user && \
	echo 'user ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/user && chmod 0440 /etc/sudoers.d/user

RUN mkdir -p /workdir && chown -R "${UID}:${GID}" /workdir
WORKDIR /workdir
	
USER user
	
CMD ["/bin/bash"]
