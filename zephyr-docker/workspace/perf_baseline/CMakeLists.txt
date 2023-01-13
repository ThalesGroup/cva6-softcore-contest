# SPDX-License-Identifier: Apache-2.0

cmake_minimum_required(VERSION 3.20.0)

find_package(Zephyr REQUIRED HINTS $ENV{ZEPHYR_BASE})

# Override standard Microsemi UART adressing with the on from Future Electronics
#set(DTC_OVERLAY_FILE ${CMAKE_CURRENT_LIST_DIR}/src/ripe.dts)

# include($ENV{ZEPHYR_BASE}/cmake/app/boilerplate.cmake NO_POLICY_SCOPE)
#project(hello_world C ASM)
project(perf_baseline)

# No shared library in Zephyr
add_library(funclib STATIC ${CMAKE_CURRENT_SOURCE_DIR}/src/funclib.c )
target_include_directories(funclib PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/src )
target_compile_options(funclib PRIVATE "-o0" )

target_sources(app PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/src/testapp.c )
target_link_libraries(app PRIVATE funclib)
target_include_directories(app PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/src )
target_compile_options(app PRIVATE "-o0" )
