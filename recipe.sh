mkdir -p ~/dipper
cd ~/dipper

# Get the toolchain
wget https://releases.linaro.org/components/toolchain/binaries/6.5-2018.12/arm-linux-gnueabi/gcc-linaro-6.5.0-2018.12-x86_64_arm-linux-gnueabi.tar.xz
wget https://releases.linaro.org/components/toolchain/binaries/6.5-2018.12/aarch64-linux-gnu/gcc-linaro-6.5.0-2018.12-x86_64_aarch64-linux-gnu.tar.xz
tar -xf gcc-linaro-6.5.0-2018.12-x86_64_arm-linux-gnueabi.tar.xz
tar -xf gcc-linaro-6.5.0-2018.12-x86_64_aarch64-linux-gnu.tar.xz

# Get the kernel source and mkbootimg
git clone git@github.com:khusika/canting_kernel_xiaomi_sdm845.git
git clone git@github.com:osm0sis/mkbootimg.git

# Setup the environment
export PATH=~/dipper/gcc-linaro-6.5.0-2018.12-x86_64_aarch64-linux-gnu/bin:$PATH
export PATH=~/dipper/gcc-linaro-6.5.0-2018.12-x86_64_arm-linux-gnueabi/bin:$PATH
export ARCH=arm64
export O=out
export CROSS_COMPILE=aarch64-linux-gnu-
export CROSS_COMPILE_ARM32=arm-linux-gnueabi-
mkdir -p canting_kernel_xiaomi_sdm845/out

# Build the kernel
cd canting_kernel_xiaomi_sdm845
copy $RECIPE_PATH/defconfig arch/arm64/configs/dipper_defconfig
make dipper_defconfig
cd out
make -j$(nproc --all)

# Copy the kernel image
cd ~/dipper/mkbootimg
make
cp ~/dipper/canting_kernel_xiaomi_sdm845/out/arch/arm64/boot/Image.gz-dtb .

# Export the vendor kernel image
adb shell cp /dev/block/by-name/boot boot.emmc.win
adb pull boot.emmc.win boot.emmc.win
unpackbootimg -i boot.emmc.win -o out/

# Create the new boot image reusing the existing ramdisk
# All the parameters here are taken from the original boot image exported with unpackbootimg
./mkbootimg --kernel out/boot.emmc.win-kernel \
  --ramdisk out/boot.emmc.win-ramdisk \
  --base 0 --os_version 10.0.0 --os_patch_level 2020-09 --board '' --pagesize 4096 \
  --hashtype sha1 --header_version 1 -o new.img
  --cmdline 'console=ttyMSM0,115200n8 earlycon=msm_geni_serial,0xA84000 androidboot.hardware=qcom androidboot.console=ttyMSM0 video=vfb:640x400,bpp=32,memsize=3072000 msm_rtb.filter=0x237 ehci-hcd.park=3 lpm_levels.sleep_disabled=1 service_locator.enable=1 swiotlb=2048 androidboot.configfs=true loop.max_part=7 androidboot.usbcontroller=a600000.dwc3 buildvariant=user'
```
