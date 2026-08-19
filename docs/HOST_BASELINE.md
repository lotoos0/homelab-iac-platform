# Homelab Host Baseline

## Operating System

- OS: Debian GNU/Linux 13 (trixie)
- Architecture: x86_64
- Kernel: Linux 6.12.100+deb13-amd64

## CPU

- Model: Intel Core i5-9400F
- Physical cores: 6
- Threads: 6
- Virtualization: Intel VT-x
- KVM device: available
- KVM kernel modules:
  - `kvm`
  - `kvm_intel`

## Memory

- Installed/available RAM: approximately 16 GB
- Swap: approximately 6 GB

## Storage

### System disk

- Capacity: approximately 120 GB
- Root filesystem: ext4
- Root filesystem free space: approximately 90 GB

### Infrastructure disk

- Capacity: approximately 1 TB
- Current filesystem: NTFS
- Current state: unmounted
- Planned use: dedicated storage for virtual machine disks
- The disk can be erased and reformatted for the project

## Networking

### Physical interfaces

- Ethernet: `enp5s0`
- Wi-Fi: `wlp3s0`
- Both interfaces are currently connected
- Ethernet currently has the preferred default route

### LAN

- Network: private IPv4 `/24`
- Gateway: local router
- DNS: local router

Exact host addresses, LAN addressing and MAC addresses are intentionally omitted from the public documentation.

## Virtualization Readiness

### KVM

Status: **READY**

Verified:

- Intel VT-x is supported
- `/dev/kvm` exists
- `kvm` kernel module is loaded
- `kvm_intel` kernel module is loaded

### QEMU / libvirt

Status: **NOT INSTALLED**

At the time of the baseline:

- No QEMU or libvirt packages were detected via `dpkg`
- `virt-host-validate` is not available

Installation and validation of the virtualization userspace stack will be handled in a later project step.

## Initial Constraints / Findings

1. The host has approximately 16 GB of RAM, so the original plan of allocating 4 GB to each of three VMs would leave too little memory for the host.
2. VM memory sizing must therefore be revised before provisioning.
3. A dedicated approximately 1 TB disk is available for VM storage.
4. The host currently has both Ethernet and Wi-Fi active on the same LAN. The final networking design should decide which interface will be used by the virtualization platform.
