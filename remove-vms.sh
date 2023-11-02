#!/bin/bash

source $(dirname $0)/vars.sh

function shutdown_vms() {
  for vmname in ${VMNAMES}; do
    sudo virsh shutdown ${vmname}
  done
}

function remove_vms() {
  for vmname in ${VMNAMES}; do
    sudo virsh shutdown ${vmname}
    sudo virsh undefine ${vmname}
    sudo rm ${IMG_DIR}/${VOL_PREFIX}-${vmname}.${IMG_EXT}
  done
}

shutdown_vms
remove_vms
