#!/bin/bash
# Copyright cc 2022 anothermi

export KBUILD_BUILD_USER=dhelo11
export KBUILD_BUILD_HOST=No-Mercy

# init
function init() {
    echo "==========================="
    echo "= START COMPILING KERNEL  ="
    echo "==========================="
}
# Main
function compile() {
    export PATH="/workspace/kernel_ginkgo/proton-clang/bin:$PATH"
    make -j$(nproc --all) O=out ARCH=arm64 santoni_defconfig
    make -j$(nproc --all) ARCH=arm64 O=out \
                          CC=clang \
                          CROSS_COMPILE=aarch64-linux-gnu- \
                          CROSS_COMPILE_ARM32=arm-linux-gnueabi-
}
#end
function ended(){
    echo "==========================="
    echo "   COMPILE KERNEL COMPLETE  "
    echo "==========================="
}

# execute
init
compile
ended
