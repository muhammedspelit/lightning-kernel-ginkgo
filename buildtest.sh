#!/bin/bash

SECONDS=0 # builtin bash timer
ZIPNAME="Sapphire-ginkgo-$(TZ=Europe/Istanbul date +"%Y%m%d-%H%M").zip"
TC_DIR="$HOME/tc/zyc-19"
AK3_DIR="$HOME/android/AnyKernel3"
DEFCONFIG="vendor/ginkgo-perf_defconfig"

export PATH="$TC_DIR/bin:$PATH"
export KBUILD_BUILD_USER="shawkteam"
export KBUILD_BUILD_HOST="builders"
export KBUILD_BUILD_VERSION="1"


curl -LSs "https://raw.githubusercontent.com/tiann/KernelSU/main/kernel/setup.sh" | bash -s main

mkdir -p out
make mrproper
make O=out ARCH=arm64 $DEFCONFIG

echo -e "\nStarting compilation...\n"
make -j$(nproc --all) O=out ARCH=arm64 CC=clang LD=ld.lld AR=llvm-ar AS=llvm-as NM=llvm-nm OBJCOPY=llvm-objcopy OBJDUMP=llvm-objdump STRIP=llvm-strip CROSS_COMPILE=$TC_DIR/aarch64-linux-gnu/bin CROSS_COMPILE_ARM32=$TC_DIR/arm-linux-gnueabi/bin CLANG_TRIPLE=aarch64-linux-gnu- Image.gz-dtb dtbo.img

if [ -f "out/arch/arm64/boot/Image.gz-dtb" ] && [ -f "out/arch/arm64/boot/dtbo.img" ]; then
echo -e "\nKernel compiled succesfully! Zipping up...\n"
if [ -d "$AK3_DIR" ]; then
cp -r $AK3_DIR AnyKernel3
elif ! git clone -q https://github.com/DeliUstaTR/AnyKernel3; then
echo -e "\nAnyKernel3 repo not found locally and cloning failed! Aborting..."
exit 1
fi
cp out/arch/arm64/boot/Image.gz-dtb AnyKernel3
cp out/arch/arm64/boot/dtbo.img AnyKernel3
rm -f *zip
cd AnyKernel3
git checkout ginkgo &> /dev/null
zip -r9 "../$ZIPNAME" * -x '*.git*' README.md *placeholder
cd ..
rm -rf AnyKernel3
rm -rf out/arch/arm64/boot
echo -e "\nCompleted in $((SECONDS / 60)) minute(s) and $((SECONDS % 60)) second(s) !"
echo "Zip: $ZIPNAME"
echo "----------------------------------"
curl -T $ZIPNAME https://oshi.at
else
echo -e "\nCompilation failed!"
exit 1
fi
