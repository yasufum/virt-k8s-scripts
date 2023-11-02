# common
VMNAMES="k8s-master k8s-node1 k8s-node2 k8s-node3"
IMG_DIR=/var/lib/libvirt/images
IMG_EXT=qcow2

# virt-install.sh
ORIG_VMNAME=ubuntu-orig  # VM name
VCPUS=4
MEM=4096  # MB
DISK_NAME=${ORIG_VMNAME}.${IMG_EXT}
DISK_SIZE=100  # GB
NW_BRIDGE=virbr0

# clone-vms.sh, remove-vms.sh
VOL_PREFIX=ubuntu2204
