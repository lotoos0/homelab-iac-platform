# VM Networking Design

> **Status:** Draft · **Version:** v0.1 · **Implementation:** Host-side network validated
>
> The libvirt network now exists on the host and matches the planned v0.1 design. VM-level DHCP, DNS, SSH and Internet connectivity still need an actual guest before I can call the whole network validated.

## Why this document exists

Before creating the first VM, I wanted to decide how networking should work instead of discovering it halfway through a Terraform configuration.

The goal for v0.1 is simple:

```text
VM <-> VM
Host <-> VM
VM -> Internet
```

All three paths should work predictably, while keeping the virtual machines separated from the physical home LAN.

For v0.1 I chose a private libvirt network with a Linux bridge, NAT and DHCP reservations. No fancy routing lab yet. I would like to actually reach the first VM before turning this into a CCNA side quest.

---

## Network model

The virtual machines will live in their own private IPv4 network managed by libvirt. The diagram below shows the planned layout, not an already deployed network.

```text
                    Internet
                       |
                 Home router
                       |
                    enp5s0
                       |
                Homelab host
                       |
                      NAT
                       |
                libvirt bridge
                 10.50.0.1
                       |
          +------------+------------+
          |            |            |
       control      worker-1     worker-2
     10.50.0.10    10.50.0.11   10.50.0.12
```

The VMs will **not be directly attached to the physical home LAN**. The homelab host will sit between both networks, giving the project its own boundary and making the VM topology independent from the addressing used by the home router.

---

## Physical uplink

The preferred physical uplink is Ethernet:

```text
enp5s0
```

At the time of the initial baseline:

```text
Ethernet route metric: 100
Wi-Fi route metric:    600
```

Lower metric wins, so the host already prefers Ethernet over Wi-Fi. The libvirt network will use host routing instead of being tied directly to `enp5s0`.

---

## Project network

The project will use:

```text
Network: 10.50.0.0/24
Gateway: 10.50.0.1
```

A `/24` provides 256 total addresses. That is massively more than I need, but the goal is not to squeeze every address out of RFC1918 space. The goal is to make debugging obvious later.

There are already several networks around the host:

| Purpose                 | Network            |
| ----------------------- | ------------------ |
| Physical home LAN       | private IPv4 `/24` |
| Docker bridge           | `172.17.0.0/16`    |
| Default libvirt network | `192.168.122.0/24` |
| Homelab IaC platform    | `10.50.0.0/24`     |

The physical LAN details are intentionally omitted. The selected subnet is easy to recognize and avoids the existing networks.

### Why not use libvirt's default network?

Libvirt already provides a NAT network called `default`, usually attached to `virbr0`. I could use it, but it is generic host configuration. The `10.50.0.0/24` network will belong to this project and should eventually be managed by Terraform.

---

## Addressing strategy

### Current decision

For v0.1 I plan to use DHCP with fixed reservations:

| Node       | IPv4 address |
| ---------- | -----------: |
| `control`  | `10.50.0.10` |
| `worker-1` | `10.50.0.11` |
| `worker-2` | `10.50.0.12` |

Addresses `10.50.0.2`-`10.50.0.9` remain available for infrastructure and future expansion.

The intended behavior is simple: when a VM boots, it requests an address through DHCP and receives its reserved address from libvirt. I still need to verify that this remains predictable after recreating a VM.

### Why reservations instead of static IPs inside the VM?

I want the infrastructure layer to own infrastructure addressing. A recreated `control` node should not depend on manually maintained network configuration hidden inside the guest operating system.

This also keeps responsibilities clear:

```text
libvirt / Terraform -> network identity
cloud-init          -> first-boot bootstrap
Ansible             -> operating system configuration
```

This is the intended responsibility split for now. I may adjust it once I start implementing VM provisioning.

### TODO

- [ ] Confirm how libvirt DHCP reservations will be represented in Terraform.
- [ ] Decide whether VM names should be resolvable through libvirt DNS.
- [ ] Verify that recreated VMs keep the expected DHCP identity.

---

## Traffic paths

The VMs will share one Linux bridge, and the host will have the gateway interface `10.50.0.1` on that network.

| Traffic path          | Planned path                                  | NAT                      |
| --------------------- | --------------------------------------------- | ------------------------ |
| VM -> VM              | directly through the Linux bridge             | No                       |
| Host -> VM            | host gateway interface -> Linux bridge        | No                       |
| VM -> Internet        | bridge -> host routing -> physical LAN        | Yes                      |
| VM -> DNS             | TBD - validate libvirt/dnsmasq behavior first | Depends on resolver path |
| Home LAN device -> VM | not required for v0.1                         | -                        |
| Internet -> VM        | not required for v0.1                         | -                        |

VM-to-VM traffic should stay inside the virtual network without involving the physical router. For now I only need the nodes to reliably reach each other over this network. Later it should become the basic network used by the Kubernetes nodes, but I am intentionally not designing Kubernetes networking here yet.

Once implemented, the host should reach each VM directly:

```bash
ping 10.50.0.10
ssh 10.50.0.10
```

This path should support Ansible, bootstrap, troubleshooting and validation scripts.

For outbound access, NAT will translate the VM's private source address to the host's address and route returning packets back to the VM. This should allow package installation, image downloads and k3s bootstrap without exposing the nodes to the home LAN.

> **TODO:** DNS behavior is not decided yet. I want to verify what libvirt gives me by default before adding another component.

---

## Security and public documentation

The repository includes the reproducible project addresses, but omits physical home infrastructure details:

- exact home LAN subnet
- exact host LAN address
- MAC addresses
- router identifiers
- public IP addresses

The goal is to document the platform, not publish my home network inventory.

---

## Manual implementation checkpoint

On 2026-08-24 I created the first version of the project network manually in libvirt.

I deliberately did this before Terraform. I want Terraform to reproduce a network I already understand and have tested, not become the place where I learn what every libvirt option does.

The resulting host-side configuration is:

| Setting           | Verified value              |
| ----------------- | --------------------------- |
| Network name      | `homelab-iac`               |
| Network           | `10.50.0.0/24`              |
| Gateway           | `10.50.0.1`                 |
| Bridge            | `virbr50`                   |
| Forward mode      | NAT                         |
| DHCP dynamic pool | `10.50.0.100`-`10.50.0.200` |
| Persistent        | Yes                         |
| Autostart         | Yes                         |
| Active            | Yes                         |

The planned node addresses `10.50.0.10`-`10.50.0.12` remain outside the dynamic DHCP pool so they can later be used as fixed reservations.

### What I actually tested

The network was defined and started with libvirt:

```bash
virsh -c qemu:///system net-define ~/homelab-iac-network.xml
virsh -c qemu:///system net-start homelab-iac
virsh -c qemu:///system net-autostart homelab-iac
```

Libvirt then reported:

```text
homelab-iac   active   autostart: yes   persistent: yes
```

The bridge created by libvirt was also verified:

```bash
ip addr show virbr50
```

with:

```text
10.50.0.1/24
```

The generated libvirt configuration confirmed:

```xml
<forward mode='nat'/>
<bridge name='virbr50' ... />
<ip address='10.50.0.1' netmask='255.255.255.0'>
```

I also restarted `libvirtd` and checked the network again:

```bash
sudo systemctl restart libvirtd
systemctl is-active libvirtd
virsh -c qemu:///system net-list --all
ip addr show virbr50
```

After the restart:

- `libvirtd` returned `active`
- `homelab-iac` remained active
- autostart remained enabled
- `virbr50` still existed
- `10.50.0.1/24` was still assigned to the bridge

The existing libvirt `default` network remained inactive and unchanged.

### What this does not prove yet

There is still no VM attached to this network, so I have **not** validated:

- DHCP reservations
- VM -> gateway connectivity
- VM -> Internet connectivity
- DNS resolution from a guest
- host -> VM SSH
- VM -> VM communication

Those checks stay open until the first test VM exists. `virbr50` currently reports `NO-CARRIER`, which is expected because there is no guest interface attached to the bridge yet.

---

## v0.1 validation

Networking v0.1 will be considered working when one test VM can:

- [ ] receive its expected DHCP reservation
- [ ] ping the gateway at `10.50.0.1`
- [ ] reach the homelab host
- [ ] reach the Internet
- [ ] resolve a public DNS name
- [ ] be reached from the host over SSH

After that I can add the remaining nodes. I do not need Kubernetes running to validate the network itself.

---

## Open questions

A few things are intentionally not decided yet:

- [ ] DNS: use libvirt/dnsmasq names or configure something separately?
- [ ] Should the host be the only machine allowed to SSH into the VM network?
- [ ] Will Kubernetes need separate subnets later for pods or services?
- [ ] Do I want direct access from my main PC to the VM network?
- [ ] Should the network lifecycle remain independent from the VM lifecycle?

I do not need answers to all of these before creating the first VM.

For v0.1 the important part is simpler: create the private network, boot one VM and prove that host -> VM and VM -> Internet work.

---

## Decision summary

| Decision        | Current plan                    |
| --------------- | ------------------------------- |
| Primary uplink  | `enp5s0` / Ethernet             |
| Virtual network | libvirt-managed private network |
| Layer 2         | Linux bridge                    |
| VM subnet       | `10.50.0.0/24`                  |
| Gateway         | `10.50.0.1`                     |
| Addressing      | DHCP with fixed reservations    |
| Nodes           | `10.50.0.10`-`10.50.0.12`       |
| Outbound access | NAT through the homelab host    |

This is enough to start implementing v0.1 without coupling the cluster directly to the physical home LAN. More advanced networking can wait until there is an actual problem that requires it.
