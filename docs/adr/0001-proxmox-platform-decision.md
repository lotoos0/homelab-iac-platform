# ADR 0001 - Use Proxmox VE as the virtualization platform

## Status

Accepted

## Context

The project originally started on a plain Debian 13 host with KVM and libvirt.

That approach was useful at the beginning because it exposed the lower virtualization layers directly:

- KVM
- QEMU
- libvirt
- Linux bridges
- dnsmasq
- NAT
- guest networking
- VM lifecycle behavior

It also helped validate the host baseline and document the initial virtualization and networking design.

The first test VM exposed a much deeper problem than expected.

The original symptom looked like a DHCP failure, but packet captures showed that the guest was not sending normal network traffic. Further testing confirmed an early reboot loop on the KVM path.

A controlled KVM vs TCG comparison narrowed the failure to the hardware virtualization path, but the exact root cause was not identified.

The unresolved KVM issue is not itself the reason for choosing Proxmox. Proxmox also relies on KVM for hardware virtualization.

The troubleshooting incident simply forced an earlier review of whether the original virtualization architecture still matched the actual goal of the project.

At that point the bigger question was no longer only "how do I fix this VM?".

The more important question became:

> Is plain Debian + libvirt actually the right virtualization platform for this project?

The homelab exists mainly to support this project. The goal is not to build a virtualization management platform from scratch. The goal is to build an IaC-driven homelab platform with repeatable provisioning, configuration, Kubernetes, GitOps and observability.

Keeping Debian + libvirt would mean continuing to build and maintain more of the VM management layer manually.

That is technically interesting, but it moves the project away from its main goal.

## Decision

Use Proxmox VE as the virtualization platform for the homelab.

Proxmox VE will replace the current plain Debian + libvirt host.

The host will be reinstalled using Proxmox VE as the base platform instead of adding Proxmox packages on top of the current Debian installation.

The project will treat Proxmox as infrastructure that should be automated, not as a GUI-first replacement for IaC.

The expected direction is:

```text
Git
  |
Terraform
  |
Proxmox API
  |
VM provisioning
  |
cloud-init
  |
Ansible
  |
Kubernetes
  |
GitOps
  |
platform services
```

The exact provider, VM template workflow and networking implementation are not decided in this ADR.

Those will be validated separately.

## Alternatives considered

### Keep Debian 13 + KVM + libvirt

This was the original design.

Advantages:

- direct control over the virtualization stack
- useful low-level learning
- fewer platform-specific abstractions
- simple dependency chain

Disadvantages:

- more manual VM lifecycle management
- more networking and storage plumbing to maintain
- more project time spent building the virtualization management layer
- weaker separation between "platform being built" and "hypervisor management"

This option is rejected for the current project direction.

It is not rejected because Debian, KVM or libvirt are bad technologies.

It is rejected because the project should spend more time on infrastructure automation and platform engineering than on rebuilding hypervisor management features.

### Install Proxmox packages on the existing Debian host

This would preserve the current Debian installation and avoid a full reinstall.

It is rejected.

The project is still early enough that preserving the current host state is not worth carrying additional uncertainty into the new platform.

A clean Proxmox installation gives a clearer baseline and makes future troubleshooting easier.

## Consequences

### Positive

- VM lifecycle, storage and networking management move to a virtualization-focused platform
- Terraform can target a dedicated virtualization API
- snapshots and backups become easier to integrate later
- the project can focus more on IaC, configuration management, Kubernetes and GitOps
- the architecture becomes easier to expand with additional nodes or services later
- the hypervisor layer becomes more explicit and easier to document

### Negative

- the current Debian host will be replaced
- existing libvirt network configuration will not be reused directly
- some existing documentation will become historical instead of current-state documentation
- the project gains a dependency on Proxmox-specific APIs and behavior
- Terraform provider selection and compatibility need separate validation
- networking needs to be redesigned for Proxmox instead of copied blindly from the libvirt design

### Documentation impact

The following existing documents describe the original Debian + libvirt phase and must be reviewed after migration:

- `docs/HOST_BASELINE.md`
- `docs/VIRTUALIZATION.md`
- `docs/NETWORKING.md`
- `docs/troubleshooting/test-vm-no-dhcp.md`

They should not be silently rewritten to pretend the original design never existed.

Where useful, they should either:

- be updated to describe the new current state,
- be marked as historical,
- or be replaced by new Proxmox-specific documentation with clear references to the earlier design.

## Validation

The decision will be considered successfully validated when:

- Proxmox VE is installed on the homelab host
- the host is reachable and manageable after installation
- hardware virtualization works correctly under Proxmox
- at least one disposable test VM boots successfully
- the VM receives working network connectivity
- the VM can reach the Internet
- the host can reach the VM
- VM provisioning can be automated through a supported API or Terraform provider

Until those checks pass, Proxmox is the selected direction, but the implementation is not considered validated.

If the same KVM-side reboot behavior appears under Proxmox VE, the platform decision will need to be revisited before continuing with Terraform, Kubernetes or any higher-level automation.

## Open questions

- Does the previous KVM reboot issue reproduce under Proxmox VE?
- Which Proxmox VE version should become the documented baseline?
- Which Terraform provider should be used?
- How should authentication for Terraform be handled?
- Should VM templates be created manually first or automated from the beginning?
- How should the Proxmox bridge and project VM network be designed?
- Should the existing `10.50.0.0/24` plan be preserved?
- How should static addressing or DHCP reservations be handled?
- Which storage backend should be used for VM disks and templates?
- What is the minimum test VM that proves the new baseline works?
