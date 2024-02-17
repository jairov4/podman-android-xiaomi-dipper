# Running containers in Android

## Introduction

To run containers in Android, you need to tackle multiple challenges.
This guide will help you to understand the challenges and how to overcome them easily.

This guide assumes that you have a Xiaomi Mi 8 (dipper) device.

## Pre-requisites

- A Xiaomi Mi 8 (dipper) device
- A computer with Linux and platform-tools installed

## Steps

### 1. Unlock the bootloader

To unlock the bootloader, you need to follow the instructions provided by Xiaomi.
You can find a guide [here](https://www.youtube.com/watch?v=tj3v4uSC2dY).
This required to root your device and run custom kernels.

### 2. Root your device

Yes, you need to root your device. There are multiple ways to root your device, but I recommend using Magisk. 
You can find the instructions to root your device [here](https://www.youtube.com/watch?v=JHORFOHS7Yw).

### 3. Build a custom kernel

To run containers in Android, you need to build a custom kernel with some specific configurations enabled.

It will require `CONFIG_POSIX_MQUEUE=y` in the kernel configuration.

```shell
./recipe.sh
```

### 4. Boot the new kernel

Boot the new kernel image either using fastboot, TWRP or flashing onto device.

```shell
adb reboot bootloader
fastboot boot new.img
```

### 5. Install LinuxDeploy

Install LinuxDeploy from the github site: https://github.com/meefik/linuxdeploy/releases/tag/2.6.0

```shell
wget https://github.com/meefik/linuxdeploy/releases/download/2.6.0/linuxdeploy-2.6.0-259.apk
adb install linuxdeploy-2.6.0-259.apk
```

### 7. Install Alpine Linux distribution

Install Alpine Linux distribution using LinuxDeploy.
Login into the Alpine Linux distribution using the default credentials as displayed in the app.
Grab the IP address from the app and use it to SSH into the device.
Then mount the cgroup folder using tmpfs just to calm down crun/podman.

```shell
ssh android@<ip_address>
sudo mkdir -p /sys/fs/cgroup
sudo mount -t tmpfs cgroup_root /sys/fs/cgroup
```

### 8. Install Podman

```shell
apk add podman mc
wget https://github.com/containers/crun/releases/download/1.14.3/crun-1.14.3-linux-arm64-disable-systemd
mv crun-1.14.3-linux-arm64-disable-systemd /usr/bin/crun
```

Then go to `/etc/containers/containers.conf` and ensure the crun is set as no cgroup runtime.

```text
runtime_supports_nocgroups = "crun"
```

Then go to `/etc/containers/storage.conf` and setup the storage driver to use `vfs`.

It happens that the default storage driver `overlay` even enabled in the kernel is complaining of
not having support for `volatile` attribute.

```text
[storage]
driver = "vfs"
```

### 9. Run containers

Now you can run containers using Podman.
You will need to disable cgroups, use host network and host ipc namespace.

```shell
podman run \
  --cgroups=disabled \ 
  --runtime /usr/bin/crun \
  --ipc=host \
  --network=host \ 
  --rm -it docker.io/library/alpine
```


## Caveats

- Podman won't have CGROUPS support to manage the resources of the containers.
- Podman won't have the ability to manage the network of the containers.
- Podman will use the vfs storage driver, which is not the best option for performance.
