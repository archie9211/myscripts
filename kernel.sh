 #
 # Script For Building Android arm64 Kernel
 #
 # Copyright (c) 2018-2019 Panchajanya1999 <rsk52959@gmail.com>
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

#! /bin/sh

#Kernel building script

KERNEL_DIR=$PWD
ARG1=$1 #It is the devicename [generally codename]
ARG2=$2 #It is the make arguments, whether clean / dirty / def_regs [regenerates defconfig]
ARG3=$3 #Build should be pushed or not [PUSH / NOPUSH]
DATE=$(TZ=Asia/Jakarta date +"%Y%m%d-%T")
export ZIPNAME="azure" #Specifies the name of kernel
#We should fetch the latest clang build from android_googlesource
export CLANG_URL=https://android.googlesource.com/platform/prebuilts/clang/host/linux-x86/+archive/0d5571d773730462d70ef218f7296a7641ff7af0/clang-r365631b.tar.gz

##----------------------------------------------------##

# START : Arguments Check
if [ $# -lt 3 ] # 3 arguments is must
  then
        echo -e "\nToo less Arguments..!! Provided - $# , Required - 3\nCheck README"
        return
  #Get outta
elif [ $# == 3 ]
  then
# START : Argument 1 [ARG1] Check
case "$ARG1" in
  "violet" ) # Execute violet function / scripts
      export DEVICE="Redmi Note 7 Pro [violet]"
      DEFCONFIG=vendor/violet-perf_defconfig
      CHATID="-1001245830369"
  ;;
  "X00T" ) # Execute X00T function / scripts
      export DEVICE="ASUS Zenfone Max Pro M1"
      DEFCONFIG=X00T_defconfig
      CHATID="-1001181445763"
  ;;
  * ) echo -e "\nError..!! Unknown device. Please add device details to script and re-execute\n"
      return
  ;;
esac # END : Argument 1 [ARG2] Check

##----------------------------------------------------##

# START : Argument 2 [ARG1] Check
case "$ARG2" in
  "clean" ) # Execute Clean build function
      alias MAKE="make clean && make mrproper && rm -rf out"
  ;;
  "dirty" ) # Do not CLEAN
      
  ;;
  "def_reg" ) # Regenerate defconfig
      export ARCH=arm64
      export SUBARCH=arm64
      make O=out $DEFCONFIG
      mv out/.config $DEFCONFIG
      echo "Defconfig Regenerated"
      exit 1;
  ;;
  * ) echo -e "\nError..!! Unknown Build Command.\n"
      return
  ;;
esac # END : Argument 2 [ARG2] Check

##---------------------------------------------------##

#START : Argument 3 [ARG3] Check
case "$ARG3" in
  "PUSH" ) # Push build to TG Channel
      build_push=true
  ;;
  "NOPUSH" ) # Do not push
      build_push=false
  ;;
  * ) echo -e "\nError..!! Unknown command. Please refer README.\n"
      return
  ;;
esac # END : Argument 3 [ARG3] Check

##-----------------------------------------------------##

else
  echo -e "\nToo many Arguments..!! Provided - $# , Required - 3\nCheck README"
  return
#Get outta
fi

##------------------------------------------------------##

#Now Its time for other stuffs like cloning, exporting, etc

function clone {
	echo " "
	echo "★★Cloning GCC Toolchain from Android GoogleSource .."
	git clone --progress -j32 --depth 5 --no-single-branch https://android.googlesource.com/platform/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9.git
	git clone --progress -j32 --depth 5 --no-single-branch https://android.googlesource.com/platform/prebuilts/gcc/linux-x86/arm/arm-linux-androideabi-4.9

	#Workaround to remove deprecation spam of gcc
	cd aarch64-linux-android-4.9
	git reset --hard 22f053ccdfd0d73aafcceff3419a5fe3c01e878b
	cd ../arm-linux-androideabi-4.9
	git reset --hard 42e5864a7d23921858ca8541d52028ff88acb2b6
	cd $KERNEL_DIR

	echo "★★GCC cloning done"
	echo ""
	echo "★★Cloning Clang 8 sources"
	wget $CLANG_URL
	mkdir clang-llvm
	tar -C clang-llvm -xvf clang*.tar.gz
	rm -rf clang*.tar.gz
	echo "★★Clang Done, Now Its time for AnyKernel .."
	git clone --depth 1 --no-single-branch https://github.com/Panchajanya1999/AnyKernel2.git -b $ARG1
	echo "★★Cloning libufdt"
	git clone https://android.googlesource.com/platform/system/libufdt $KERNEL_DIR/scripts/ufdt/libufdt
	echo "★★Cloning Kinda Done..!!!"
}

##------------------------------------------------------##

function exports {
	export KBUILD_BUILD_USER="panchajanya"
	export KBUILD_BUILD_HOST="circleci"
	export ARCH=arm64
	export SUBARCH=arm64
	export KBUILD_COMPILER_STRING=$($KERNEL_DIR/clang-llvm/bin/clang --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g' -e 's/[[:space:]]*$//')
	LD_LIBRARY_PATH=$KERNEL_DIR/clang-llvm/lib64:$LD_LIBRARY_PATH
	export LD_LIBRARY_PATH
	PATH=$KERNEL_DIR/clang-llvm/bin/:$KERNEL_DIR/aarch64-linux-android-4.9/bin/:$PATH
	export PATH
	export BOT_MSG_URL="https://api.telegram.org/bot$token/sendMessage"
	export BOT_BUILD_URL="https://api.telegram.org/bot$token/sendDocument"
	env_exports
	export PROCS=$(nproc --all)
}

##---------------------------------------------------------##

function tg_post_msg {
	curl -s -X POST "$BOT_MSG_URL" -d chat_id="$2" \
	-d "disable_web_page_preview=true" \
	-d "parse_mode=html" \
	-d text="$1"

}

##----------------------------------------------------------------##

function tg_post_build {
	curl --progress-bar -F document=@"$1" $BOT_BUILD_URL \
	-F chat_id="$2"  \
	-F "disable_web_page_preview=true" \
	-F "parse_mode=html" \
	-F caption="$3"  
}

##----------------------------------------------------------##

function env_exports {
	export CROSS_COMPILE=$KERNEL_DIR/aarch64-linux-android-4.9/bin/aarch64-linux-android-
	export CROSS_COMPILE_ARM32=$KERNEL_DIR/arm-linux-androideabi-4.9/bin/arm-linux-androideabi-
	export CC=$KERNEL_DIR/clang-llvm/bin/clang
	}

##----------------------------------------------------------##

function build_kernel {
	if [ "$build_push" = true ]; then
		tg_post_msg "<b>$CIRCLE_BUILD_NUM CI Build Triggered</b>%0A<b>Date : </b><code>$(TZ=Asia/Jakarta date)</code>%0A<b>Device : </b><code>$DEVICE</code>%0A<b>Pipeline Host : </b><code>CircleCI</code>%0A<b>Host Core Count : </b><code>$PROCS</code>%0A<b>Compiler Used : </b><code>$KBUILD_COMPILER_STRING</code>%0a<b>Branch : </b><code>$CIRCLE_BRANCH</code>%0A<b>Status : </b>#Nightly" "$CHATID"
	fi
	make O=out $DEFCONFIG
	BUILD_START=$(date +"%s")
	make -j$PROCS O=out \
		CROSS_COMPILE=$CROSS_COMPILE \
		CROSS_COMPILE_ARM32=$CROSS_COMPILE_ARM32 \
		CC=$CC \
		CLANG_TRIPLE=aarch64-linux-gnu- 2>&1 | tee error.log
	#make dtbo image
	make O=out dtbo.img
	BUILD_END=$(date +"%s")
	DIFF=$((BUILD_END - BUILD_START))
	check_img
}

##-------------------------------------------------------------##

function check_img {
	if [ -f $KERNEL_DIR/out/arch/arm64/boot/Image.gz-dtb ] 
	    then
		gen_zip
	else
		tg_post_build "error.log" "$CHATID" "<b>Build failed to compile after $((DIFF / 60)) minute(s) and $((DIFF % 60)) seconds</b>"
	fi
}

##--------------------------------------------------------------##

function gen_zip {
	mv $KERNEL_DIR/out/arch/arm64/boot/Image.gz-dtb AnyKernel2/Image.gz-dtb
	mv $KERNEL_DIR/out/arch/arm64/boot/dtbo.img AnyKernel2/dtbo.img
	cd AnyKernel2
	zip -r9 $ZIPNAME-$ARG1-$DATE * -x .git README.md
	MD5CHECK=$(md5sum $ZIPNAME-$ARG1-$DATE.zip | cut -d' ' -f1)
	tg_post_build $ZIPNAME* "$CHATID" "Build took : $((DIFF / 60)) minute(s) and $((DIFF % 60)) second(s) | MD5 Checksum : <code>$MD5CHECK</code>"
	cd ..
}

clone
exports
build_kernel

##----------------*****-----------------------------##
