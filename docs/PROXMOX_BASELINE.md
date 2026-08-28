# Proxmox VE Baseline

## Status

Validated

The base Proxmox VE installation is working on the homelab host.

The previous early KVM guest reboot loop observed on Debian + libvirt did not reproduce during the first Proxmox VM validation.

This does not explain the old KVM issue. It only confirms that the current Proxmox baseline is stable enough to continue.

## Host

```text
CPU: Intel Core i5-9400F
CPU cores: 6
Virtualization: Intel VT-x
RAM: 15 GiB usable
Swap: 8 GiB
```

KVM is available on the host:

```text
kvm_intel
kvm
/dev/kvm
```

The additional 2x8 GB Ballistix modules were not added yet because their condition is unknown.

I want to keep the first Proxmox baseline on the known-good 16 GB RAM configuration and test the extra memory separately later.

## Proxmox version

After the initial installation and package upgrade:

```text
proxmox-ve: 9.2.0
pve-manager: 9.2.11
running kernel: 7.0.14-14-pve
```

The host was rebooted after the kernel update and came back normally.

## Network

Management networking:

```text
Hostname: homelab-pve.home.arpa
Management IP: 192.168.33.11/24
Gateway: 192.168.33.1
DNS: 192.168.33.1
Bridge: vmbr0
Physical uplink: nic0
```

The management IP is assigned to `vmbr0`.

The physical Ethernet interface is attached to the bridge and does not hold the host IP directly.

Wi-Fi is not used for Proxmox management.

## Storage

### System SSD

```text
Device: /dev/sda
Model: Apacer AS340 120GB
Filesystem: ext4
Layout: LVM + LVM-thin
```

Current Proxmox storage:

```text
local
local-lvm
```

The first test VM disk is stored on `local-lvm`.

### Additional HDD

```text
Device: /dev/sdb
Model: TOSHIBA HDWD110
Size: 1 TB
Filesystem: ext4
Label: pve-hdd
Mount point: /mnt/pve/hdd-data
```

The disk was cleared and added to Proxmox as:

```text
Storage ID: hdd-data
Type: Directory
Shared: no
```

Enabled content types:

```text
Disk image
ISO image
Container template
Backup
Snippets
```

`pvesm status` confirmed all three storages as active:

```text
hdd-data
local
local-lvm
```

## KVM validation

The host reports Intel VT-x and loads the expected KVM modules:

```text
kvm_intel
kvm
```

`/dev/kvm` is present.

The first validation VM was intentionally created with a simple Proxmox default configuration instead of immediately tuning CPU models or machine types.

The goal was to check whether the previous early reboot loop appears under a normal Proxmox KVM setup.

It did not.

The VM remained in the `running` state during repeated status checks and reached the Debian installer normally.

After installation, the guest booted from its virtual disk and reached the login prompt without entering a reboot loop.

## Test VM

```text
VM ID: 100
Name: test-vm
Guest: Debian 13
CPU: 1 core
CPU type: x86-64-v2-AES
RAM: 2048 MiB
Disk: 32 GiB
Disk storage: local-lvm
Network model: VirtIO
Bridge: vmbr0
```

The guest received:

```text
192.168.33.14/24
```

Validation results:

```text
Guest boot: PASS
KVM stability: PASS
DHCP: PASS
Gateway: PASS
Internet access: PASS
DNS resolution: PASS
Host to guest connectivity: PASS
SSH: PASS
```

The guest successfully reached:

```text
192.168.33.1
1.1.1.1
deb.debian.org
```

The Proxmox host also reached the guest, and SSH from the main workstation to:

```text
lotoos0@192.168.33.14
```

worked successfully.

## Validation result

The Proxmox baseline is stable enough to continue with the project.

The most important result is that the previous KVM reboot behavior did not reproduce with the first Proxmox test VM.

The current state proves:

- the host boots reliably
- Proxmox management networking works
- KVM is available
- one VM can boot and remain stable
- guest networking works
- the host can reach the guest
- SSH access works
- the additional HDD is mounted and available as Proxmox storage

This is enough to move past the hypervisor baseline and start planning the automation layer.

## Open questions

- Should the extra 2x8 GB Ballistix RAM be added after a separate memory test?
- Should the existing `10.50.0.0/24` VM network plan still be used under Proxmox?
- Which Terraform provider should be used?
- How should Terraform authenticate to the Proxmox API?
- Should VM templates be created manually first or built automatically?
- Which workloads should use `local-lvm` and which should use `hdd-data`?
