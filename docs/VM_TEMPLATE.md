# VM Template

## Goal

Create a reusable Debian 13 cloud image template in Proxmox that Terraform can clone for disposable VMs.

The template should stay as generic as possible. VM-specific settings such as hostname, SSH access and later node roles should ideally be provided during provisioning instead of being baked into the image.

---

## Current template

The current template was created manually on the Proxmox host.

- VM ID: `9000`
- Name: `debian-13-cloud-template`
- Base image: Debian 13 genericcloud, amd64, QCOW2
- Storage: `local-lvm`
- CPU: 2 vCPU
- RAM: 2048 MB
- Network: VirtIO on `vmbr0`
- Cloud-init drive: `ide2`
- IP configuration: DHCP
- Console: serial
- Template flag: enabled

The current workflow is still manual. Terraform consumes this template, but does not create it yet.

## Manual build

I created the template manually first instead of trying to automate a process I had not tested yet.

The base image is the official Debian 13 genericcloud image:

```text
debian-13-genericcloud-amd64.qcow2
```

The workflow was:

```text
Debian cloud image
-> create VM 9000
-> import QCOW2 disk
-> attach disk as scsi0
-> add cloud-init drive
-> enable DHCP
-> enable serial console
-> convert VM to template
```

This gave me a known-good template that Terraform can clone.

For now, creating the template itself is still outside Terraform. That is intentional - first I wanted to prove that the image, cloud-init and clone workflow actually work.

---

## Cloud-init access

The first Terraform clone booted correctly, but I could not log in because the template did not yet contain a usable cloud-init user or SSH key.

Instead of adding a temporary password, I updated the template with:

- cloud-init user: `debian`
- SSH public key
- DHCP on `ipconfig0`

After recreating the VM through Terraform, the clone inherited those settings.

Validation:

```text
Terraform destroy
-> Terraform apply
-> VM boot
-> DHCP lease
-> SSH with key
```

The recreated VM received `192.168.33.13` during the test and was reachable with:

```bash
ssh debian@192.168.33.13
```

The exact DHCP address is not treated as permanent infrastructure yet. Final VM addressing is still an open question.

---

## Terraform clone proof

Terraform now clones the Proxmox template through the `bpg/proxmox` provider.

The first successful apply created:

```text
VM ID: 101
Name: tf-test-vm
State: running
```

The clone used template `9000` and started automatically after creation.

During the first apply I hit one missing permission:

```text
Permission check failed (/sdn/zones/localnetwork/vmbr0, SDN.Use)
```

I added only `SDN.Use` to the custom `TerraformVM` role instead of replacing it with a broad admin role.

After that:

```text
terraform apply
-> VM created

terraform plan
-> No changes
```

That confirmed both the clone workflow and a stable second plan without unexpected drift.

---

## Open questions / TODO

The current template workflow is good enough for the first Terraform proof, but it is not final yet.

Still open:

- decide whether template creation should stay manual or move into automation later
- decide final VM addressing instead of relying on DHCP
- confirm whether QEMU Guest Agent should be installed in the base image
- decide whether the template should stay at 3 GB or use a larger default disk
- move SSH key injection out of the manually prepared template if Terraform can own it cleanly
- document the final template lifecycle once the VM model stops changing

For now, the important part is proven:

```text
template 9000
-> Terraform clone
-> cloud-init
-> network
-> SSH
-> stable second plan
```

That is enough to continue M2 without pretending the template workflow is finished.

---

## Validation

Current status:

- `PASS` - Debian 13 genericcloud image imported successfully
- `PASS` - template `9000` created in Proxmox
- `PASS` - Terraform can read the template
- `PASS` - Terraform can clone the template
- `PASS` - cloned VM boots
- `PASS` - DHCP works
- `PASS` - SSH key login works
- `PASS` - second `terraform plan` returns no changes

This is enough for the first disposable VM proof.

The template workflow is still a draft. It works, but I expect it to change once Terraform, cloud-init ownership and final VM networking are cleaned up.
