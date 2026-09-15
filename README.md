# homelab-iac-platform

From bare-metal homelab to a reproducible Kubernetes platform built on Proxmox VE.

Current state:

- Proxmox VE as the virtualization platform
- Terraform with the `bpg/proxmox` provider
- reusable Debian 13 cloud-init template
- first disposable VM provisioning validated

Planned next layers:

- Ansible for base OS configuration
- Kubernetes cluster bootstrap and node lifecycle

Detailed implementation notes and decisions live in [`docs/`](docs/).
