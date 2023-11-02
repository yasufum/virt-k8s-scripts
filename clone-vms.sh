#!/bin/bash

VMNAMES="k8s-master k8s-node1 k8s-node2 k8s-node3"

ORIG_NAME=ubuntu-orig
VOL_DIR=/var/lib/libvirt/images
VOL_PREFIX=ubuntu2204
EXT=qcow2

function virt_clone() {
  for vmname in ${VMNAMES}; do
    sudo virt-clone --original ${ORIG_NAME} --name ${vmname} \
      --file ${VOL_DIR}/${VOL_PREFIX}-${vmname}.${EXT}
  done
}

function start_vms() {
  for vmname in ${VMNAMES}; do
    sudo virsh start ${vmname}
  done
}

virt_clone
start_vms
