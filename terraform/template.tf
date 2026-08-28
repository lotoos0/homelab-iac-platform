data "proxmox_vm" "debian_template" {
  node_name = "homelab-pve"
  id        = 9000
}
