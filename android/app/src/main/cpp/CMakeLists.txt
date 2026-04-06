cmake_minimum_required(VERSION 3.22.1)
project("pocketlm_hardware" VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Optimization flags
set(CMAKE_CXX_FLAGS_RELEASE "-O2")

# All our source files
add_library(
    pocketlm_hardware
    SHARED

    hardware/pocketlm_hardware.cpp
    hardware/ram_reader.cpp
    hardware/cpu_reader.cpp
    hardware/gpu_reader.cpp
    hardware/storage_reader.cpp
    hardware/thermal_reader.cpp
)

# Android system libraries we need
target_link_libraries(
    pocketlm_hardware
    android      # Android NDK
    log          # __android_log_print
)

# Include our headers
target_include_directories(
    pocketlm_hardware
    PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/hardware
)