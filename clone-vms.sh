#!/bin/bash

source $(dirname $0)/vars.sh

function virt_clone() {
  for vmname in ${VMNAMES}; do
    sudo virt-clone --original ${ORIG_VMNAME} --name ${vmname} \
      --file ${IMG_DIR}/${VOL_PREFIX}-${vmname}.${IMG_EXT}
  done
}

function start_vms() {
  for vmname in ${VMNAMES}; do
    sudo virsh start ${vmname}
  done
}

virt_clone
start_vms
