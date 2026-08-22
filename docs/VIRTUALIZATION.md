# Virtualization Host

## Stack

The homelab host uses KVM/QEMU with libvirt as the virtualization layer.

The virtualization stack includes:

- QEMU
- KVM
- libvirt
- `virsh`
- `virt-install`

## Validation

Host virtualization was validated using:

```bash
virt-host-validate qemu
```

The following requirements passed:

- hardware virtualization support
- `/dev/kvm` availability
- `/dev/kvm` access for the project user
- `/dev/vhost-net`
- `/dev/net/tun`
- required CPU, memory and block I/O cgroup checks

System-level libvirt access was also verified with:

```bash
virsh -c qemu:///system list --all
```

The command completes successfully without requiring root privileges.

## User Access

The project user belongs to:

- `kvm`
- `libvirt`

This allows normal virtualization operations without using `sudo virsh`.

## Known Validation Warnings

### cgroup devices

The host uses cgroups v2.

`virt-host-validate` reports a warning for the `devices` controller when executed as an unprivileged user. This does not currently block QEMU/KVM operation.

### IOMMU

IOMMU validation reports a warning.

Device passthrough is not required by the current project scope, so this is not considered a blocker for v0.1.

### Secure Guest

Secure Guest support could not be determined.

Secure/confidential guest virtualization is outside the current project scope and is not required for v0.1.

## Status

**QEMU/KVM host readiness: PASS**
