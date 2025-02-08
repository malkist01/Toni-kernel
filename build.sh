#!/bin/bash
# shellcheck disable=SC2154

 # Script For Building Android arm64 Kernel
 #
 # Copyright (c) 2018-2021 Panchajanya1999 <rsk52959@gmail.com>
 #
 # Licensed under the Apache License, Version 2.0 (the "License");
 # you may not use this file except in compliance with the License.
 # You may obtain a copy of the License at
 #
 #      http://www.apache.org/licenses/LICENSE-2.0
 #
 # Unless required by applicable law or agreed to in writing, software
 # distributed under the License is distributed on an "AS IS" BASIS,
 # WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 # See the License for the specific language governing permissions and
 # limitations under the License.
 #

# Kernel building script
WORKDIR="$(pwd)"
KERNEL="$WORKDIR/aikernel"

# Cloning Sources
#git clone --single-branch --depth=1 https://github.com/Asyanx/sea_kernel_xiaomi_sm6225 -b sea-r-oss $KERNEL && cd $KERNEL
cd $KERNEL
export LOCALVERSION="L9_Acheron⚔闇ノ月"

# Bail out if script fails
set -e

# Function to show an informational message
msger()
{
        while getopts ":n:e:" opt
        do
                case "${opt}" in
                        n) printf "[*] $2 \n" ;;
                        e) printf "[×] $2 \n"; return 1 ;;
                esac
        done
}

cdir()
{
        cd "$1" 2>/dev/null || msger -e "The directory $1 doesn't exists !"
}

##------------------------------------------------------##
##----------Basic Informations, COMPULSORY--------------##

# The defult directory where the kernel should be placed
KERNEL_DIR="$(pwd)"
BASEDIR="$(basename "$KERNEL_DIR")"

# PATCH KERNELSU & RELEASE VERSION
KSU=1
RELEASE=L8
if [ $KSU = 1 ]
then
        echo "CONFIG_KSU=y" >> arch/arm64/configs/"teletubies_defconfig"
        echo "# CONFIG_KSU_DEBUG is not set" >> arch/arm64/config/"teletubies_defconfig"
        echo "CONFIG_KSU_SUSFS=y" >> arch/arm64/configs/"teletubies_defconfig"
        KSU_GIT_VERSION=$(cd KernelSU && git rev-list --count HEAD)
        KERNELSU_VERSION=$(($KSU_GIT_VERSION + 10000 + 200))
fi

# Banner overwrite ( for kernel installation branding )
# 1 = yes | 0 = no
BANNER_OVERWRITE=1

# The name of the Kernel, to name the ZIP
ZIPNAME="AiKernel"
if [ $KSU = 1 ]
then
   VER="$RELEASE-Origin"
else
    VER="$RELEASE-Faith"
fi

# Build Author
# Take care, it should be a universal and most probably, case-sensitive
AUTHOR="malkist"
HOSTR="android-server"

# Architecture
ARCH=arm64

# The name of the device for which the kernel is built
MODEL="Redmi 4X"

# The codename of the device
DEVICE="santoni"

# The defconfig which should be used. Get it from config.gz from
# your device or check source
DEFCONFIG=teletubies_defconfig

# Specify compiler.
# 'clang' or 'gcc'
COMPILER=clang

# Build modules. 0 = NO | 1 = YES
MODULES=0

# Specify linker.
# 'ld.lld'(default)
LINKER=ld.lld

# Clean source prior building. 1 is NO(default) | 0 is YES
INCREMENTAL=0

# Push ZIP to Telegram. 1 is YES | 0 is NO(default)
PTTG=1
# if [ $PTTG = 1 ]
# then
#         # Set Telegram Chat ID
#         CHATID="-1002287610863"
#         TOKEN="7596553794:AAGoeg4VypmUfBqfUML5VWt5mjivN5-3ah8"
# fi

# Generate a full DEFCONFIG prior building. 1 is YES | 0 is NO(default)
DEF_REG=0

# Files/artifacts
FILES=Image.gz

# Build dtbo.img (select this only if your source has support to building dtbo.img)
# 1 is YES | 0 is NO(default)
BUILD_DTBO=0

# Sign the zipfile
# 1 is YES | 0 is NO
SIGN=0
if [ $SIGN = 1 ]
then
        #Check for java
        if ! hash java 2>/dev/null 2>&1; then
                SIGN=0
                msger -n "you may need to install java, if you wanna have Signing enabled"
        else
                SIGN=1
        fi
fi

# Silence the compilation
# 1 is YES(default) | 0 is NO
SILENCE=0

# Verbose build
# 0 is Quiet(default)) | 1 is verbose | 2 gives reason for rebuilding targets
VERBOSE=0

# Debug purpose. Send logs on every successfull builds
# 1 is YES | 0 is NO(default)
LOG_DEBUG=0

##------------------------------------------------------##
##---------Do Not Touch Anything Beyond This------------##

# Check if we are using a dedicated CI ( Continuous Integration ), and
# set KBUILD_BUILD_VERSION and KBUILD_BUILD_HOST and CI_BRANCH

## Set defaults first

# shellcheck source=/etc/os-release
export DISTRO=$(source /etc/os-release && echo "${NAME}")
export KBUILD_BUILD_HOST=$(uname -a | awk '{print $2}')
TERM=xterm

#Check Kernel Version
KERVER=$(make kernelversion)

# Set a commit head
COMMIT_HEAD=$(git log --oneline -1)

# Set Date
DATE=$(TZ=Asia/Jakarta date +"%Y%m%d-%T")
WAKTU=$(date +"%F-%S")

#Now Its time for other stuffs like cloning, exporting, etc

do_install_pkg(){
        sudo apt update -y
        sudo apt upgrade -y
        sudo apt install python3 cpio bc flex -y
}

 clone()
 {
        echo " "
        if [ $COMPILER = "gcc" ]
        then
                msger -n "|| Cloning GCC 9.3.0 baremetal ||"
                git clone --depth=1 https://github.com/mvaisakh/gcc-arm64.git gcc64
                git clone --depth=1 https://github.com/arter97/arm32-gcc.git gcc32
                GCC64_DIR=$KERNEL_DIR/gcc64
                GCC32_DIR=$KERNEL_DIR/gcc32
        fi

        if [ $COMPILER = "clang" ]
        then
                mkdir clang-llvm
                wget https://github.com/ZyCromerZ/Clang/releases/download/21.0.0git-20250208-release/Clang-21.0.0git-20250208.tar.gz -O "Clang-21.0.0git-20250208.tar.gz"
                tar -xf Clang-21.0.0git-20250208.tar.gz -C clang-llvm
                git clone https://github.com/ZyCromerZ/aarch64-zyc-linux-gnu -b 14 gcc64 --depth=1
                git clone https://github.com/ZyCromerZ/arm-zyc-linux-gnueabi -b 14 gcc32 --depth=1
                GCC64_DIR=$KERNEL_DIR/gcc64
                GCC32_DIR=$KERNEL_DIR/gcc32
                  for64=aarch64-zyc-linux-gnu
                  for32=arm-zyc-linux-gnueabi
                # Toolchain Directory defaults to clang-llvm
                TC_DIR=$KERNEL_DIR/clang-llvm
                  export LLVM=1
                export LLVM_IAS=1
                export LD_LIBRARY_PATH=$TC_DIR/bin/:$GCC64_DIR/bin/:$GCC32_DIR/bin/:$LD_LIBRARY_PATH
                MorePlusPlus="LD=$for64-ld LDGOLD=$for64-ld.gold HOSTLD=${TC_DIR}/bin/ld $MorePlusPlus"
                MorePlusPlus="LD_COMPAT=${GCC32_DIR}/bin/$for32-ld $MorePlusPlus"
        fi

        msger -n "|| Cloning Anykernel ||"
        git clone --depth=1 https://github.com/malkist01/anykernel.git -b master AnyKernel3

        if [ $BUILD_DTBO = 1 ]
        then
                msger -n "|| Cloning libufdt ||"
                #git clone https://android.googlesource.com/platform/system/libufdt "$KERNEL_DIR"/scripts/ufdt/libufdt
        fi
}

##------------------------------------------------------##

exports()
{
        KBUILD_BUILD_USER=$AUTHOR
        KBUILD_BUILD_HOST=$HOSTR
        SUBARCH=$ARCH
        CUSTOMSTR="[Origin] Semi-OC msm4.19-merge ~Personal //"

        if [ $COMPILER = "clang" ]
        then
                KBUILD_COMPILER_STRING=$("$TC_DIR"/bin/clang --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g' -e 's/[[:space:]]*$//')
                PATH=$TC_DIR/bin/:$GCC64_DIR/bin/:$GCC32_DIR/bin/:/usr/bin:$PATH
        elif [ $COMPILER = "gcc" ]
        then
                KBUILD_COMPILER_STRING=$("$GCC64_DIR"/bin/aarch64-elf-gcc --version | head -n 1)
                PATH=$GCC64_DIR/bin/:$GCC32_DIR/bin/:/usr/bin:$PATH
        fi

        BOT_MSG_URL="https://api.telegram.org/bot$TOKEN/sendMessage"
        BOT_BUILD_URL="https://api.telegram.org/bot$TOKEN/sendDocument"
        PROCS=$(nproc --all)

        export KBUILD_BUILD_USER ARCH SUBARCH PATH \
               KBUILD_COMPILER_STRING BOT_MSG_URL \
               BOT_BUILD_URL PROCS CUSTOMSTR
}

##---------------------------------------------------------##

tg_post_msg()
{
        curl -s -X POST "$BOT_MSG_URL" -d chat_id="$CHATID" \
        -d "disable_web_page_preview=true" \
        -d "parse_mode=html" \
        -d text="$1"

}

##----------------------------------------------------------##

tg_post_build()
{
        # Post MD5Checksum alongwith for easeness
        MD5CHECK=$(md5sum "$1" | cut -d' ' -f1)

        # Show the Checksum alongwith caption
        curl --progress-bar -F document=@"$1" "$BOT_BUILD_URL" \
        -F chat_id="$CHATID"  \
        -F "disable_web_page_preview=true" \
        -F "parse_mode=Markdown" \
        -F caption="$2 | *MD5 Checksum : *\`$MD5CHECK\`"
}

##----------------------------------------------------------##

build_kernel()
{
        if [ $INCREMENTAL = 0 ]
        then
                msger -n "|| Cleaning Sources ||"
                make mrproper && rm -rf out
        fi

        if [ "$KSU" = 1 ]
         then
                tg_post_msg "<b>Sea CI Build Triggered</b>%0A<b>Docker OS: </b><code>$DISTRO</code>%0A<b>Kernel Version : </b><code>$KERVER</code>%0A<b>Date : </b><code>$(TZ=Asia/Jakarta date)</code>%0A<b>Device : </b><code>$MODEL [$DEVICE]</code>%0A<b>Host Core Count : </b><code>$PROCS</code>%0A<b>Compiler Used : </b><code>$KBUILD_COMPILER_STRING</code>%0A<b>KernelSU: </b><code>$KERNELSU_VERSION</code>%0A<b>Top Commit : </b><code>$COMMIT_HEAD</code>"
        else
                tg_post_msg "<b>Sea CI Build Triggered</b>%0A<b>Docker OS: </b><code>$DISTRO</code>%0A<b>Kernel Version : </b><code>$KERVER</code>%0A<b>Date : </b><code>$(TZ=Asia/Jakarta date)</code>%0A<b>Device : </b><code>$MODEL [$DEVICE]</code>%0A<b>Host Core Count : </b><code>$PROCS</code>%0A<b>Compiler Used : </b><code>$KBUILD_COMPILER_STRING</code>%0A<b>NON KernelSU:<code>This is not KSU</code>%0A</b><b>Top Commit : </b><code>$COMMIT_HEAD</code>"
            fi

        make O=out $DEFCONFIG
        if [ $DEF_REG = 1 ]
        then
                cp .config arch/arm64/configs/$DEFCONFIG
                git add arch/arm64/configs/$DEFCONFIG
                git commit -m "$DEFCONFIG: Regenerate

                                                This is an auto-generated commit"
        fi

        BUILD_START=$(date +"%s")
        if [ $COMPILER = "clang" ]
        then
                MAKE+=(
                          CC=clang \
                        CROSS_COMPILE=aarch64-zyc-linux-gnu- \
                        CROSS_COMPILE_ARM32=arm-zyc-linux-gnueabi- \
                           CLANG_TRIPLE=aarch64-linux-gnu- \
                        HOSTCC=gcc \
                          HOSTCXX=g++ ${MorePlusPlus}
     ) 
        elif [ $COMPILER = "gcc" ]
        then
                MAKE+=(
                        CROSS_COMPILE_ARM32=arm-eabi- \
                        CROSS_COMPILE=aarch64-elf- \
                        AR=aarch64-elf-ar \
                        OBJDUMP=aarch64-elf-objdump \
                        STRIP=aarch64-elf-strip \
                        NM=aarch64-elf-nm \
                        OBJCOPY=aarch64-elf-objcopy \
                        LD=aarch64-elf-$LINKER
                )
        fi

        if [ $SILENCE = "1" ]
        then
                MAKE+=( -s )
        fi

        msger -n "|| Started Compilation ||"
        make -kj"$PROCS" O=out \
                V=$VERBOSE \
                "${MAKE[@]}" 2>&1 | tee error.log
        if [ $MODULES = "1" ]
        then
            msger -n "|| Started Compiling Modules ||"
            make -j"$PROCS" O=out \
                 "${MAKE[@]}" modules_prepare
            make -j"$PROCS" O=out \
                 "${MAKE[@]}" modules INSTALL_MOD_PATH="$KERNEL_DIR"/out/modules
            make -j"$PROCS" O=out \
                 "${MAKE[@]}" modules_install INSTALL_MOD_PATH="$KERNEL_DIR"/out/modules
            find "$KERNEL_DIR"/out/modules -type f -iname '*.ko' -exec cp {} AnyKernel3/modules/system/lib/modules/ \;
        fi

                BUILD_END=$(date +"%s")
                DIFF=$((BUILD_END - BUILD_START))

                if [ -f "$KERNEL_DIR"/out/arch/arm64/boot/$FILES ]
                then
                        msger -n "|| Kernel successfully compiled ||"
                        if [ $BUILD_DTBO = 1 ]
                        then
                                msger -n "|| Building DTBO ||"
                                tg_post_msg "<code>Building DTBO..</code>"
                                python3 "$KERNEL_DIR/scripts/ufdt/libufdt/utils/src/mkdtboimg.py" \
                                        create "$KERNEL_DIR/out/arch/arm64/boot/dtbo.img" --page_size=4096 "$KERNEL_DIR/out/arch/arm64/boot/dts/$DTBO_PATH"
                        fi
                                gen_zip
                        else
                        if [ "$PTTG" = 1 ]
                         then
                                tg_post_build "error.log" "*Build failed to compile after $((DIFF / 60)) minute(s) and $((DIFF % 60)) seconds*"
                        fi
                fi

}

##--------------------------------------------------------------##

gen_zip()
{
        msger -n "|| Zipping into a flashable zip ||"
        mv "$KERNEL_DIR"/out/arch/arm64/boot/$FILES AnyKernel3/$FILES
        if [ $BUILD_DTBO = 1 ]
        then
                mv "$KERNEL_DIR"/out/arch/arm64/boot/dtbo.img AnyKernel3/dtbo.img
        fi

    if [ $BANNER_OVERWRITE = 1 ]; then
        echo "|| Waiting for new 'banner' file save... ||"
        code banner --wait
        mv banner AnyKernel3/banner
        echo "|| Banner saved ||"
    fi

        cdir AnyKernel3
        zip -r $ZIPNAME-$DEVICE-$VER-"$WAKTU" . -x ".git*" -x "README.md" -x "*.zip"

        ## Prepare a final zip variable
        ZIP_FINAL="$ZIPNAME-$DEVICE-$VER-$WAKTU"

        if [ $SIGN = 1 ]
        then
                ## Sign the zip before sending it to telegram
                if [ "$PTTG" = 1 ]
                 then
                         msger -n "|| Signing Zip ||"
                        tg_post_msg "<code>Signing Zip file with AOSP keys..</code>"
                 fi
                curl -sLo zipsigner-3.0.jar https://github.com/Magisk-Modules-Repo/zipsigner/raw/master/bin/zipsigner-3.0-dexed.jar
                java -jar zipsigner-3.0.jar "$ZIP_FINAL".zip "$ZIP_FINAL"-signed.zip
                ZIP_FINAL="$ZIP_FINAL-signed"
        fi

        if [ "$PTTG" = 1 ]
         then
                tg_post_build "$ZIP_FINAL.zip" "Build took : $((DIFF / 60)) minute(s) and $((DIFF % 60)) second(s)"
        fi
        cd ..
}

do_install_pkg
clone
exports
build_kernel

if [ $LOG_DEBUG = "1" ]
then
        tg_post_build "error.log" "$CHATID" "Debug Mode Logs"
fi

##----------------*****-----------------------------##