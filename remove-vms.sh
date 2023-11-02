#!/bin/bash

VMNAMES="k8s-master k8s-node1 k8s-node2 k8s-node3"

VOL_DIR=/var/lib/libvirt/images
VOL_PREFIX=ubuntu2204
EXT=qcow2

function shutdown_vms() {
  for vmname in ${VMNAMES}; do
    sudo virsh shutdown ${vmname}
  done
}

function remove_vms() {
  for vmname in ${VMNAMES}; do
    sudo virsh shutdown ${vmname}
    sudo virsh undefine ${vmname}
    sudo rm ${VOL_DIR}/${VOL_PREFIX}-${vmname}.${EXT}
  done
}

shutdown_vms
remove_vms
