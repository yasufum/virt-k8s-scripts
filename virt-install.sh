#!/bin/bash

# NOTE: Use `--location` instead of `--cdrom` because `--extra-args` for none
# graphical install via console cannot accept `--cdrom`.

NAME=ubuntu-orig  # VM name
VCPUS=4
MEM=4096  # MB
DISK_NAME=${NAME}.img
DISK_SIZE=20  # GB
NW_BRIDGE=virbr0

IMGDIR=/var/lib/libvirt/images

# https://releases.ubuntu.com/jammy/
# https://releases.ubuntu.com/jammy/ubuntu-22.04.3-live-server-amd64.iso
LOCATION=${IMGDIR}/ubuntu-22.04.3-live-server-amd64.iso
OS_VARIANT=ubuntu22.04

sudo virt-install \
--name ${NAME} \
--ram ${MEM} \
--disk path=${IMGDIR}/${DISK_NAME},size=${DISK_SIZE} \
--vcpus ${VCPUS} \
--os-variant ${OS_VARIANT} \
--network bridge=${NW_BRIDGE} \
--graphics none \
--console pty,target_type=serial \
--location ${LOCATION},kernel=casper/vmlinuz,initrd=casper/initrd \
--extra-args 'console=ttyS0,115200n8'
