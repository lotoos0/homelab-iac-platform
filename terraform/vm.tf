resource "proxmox_cloned_vm" "test" {
  node_name = "homelab-pve"
  name      = "tf-test-vm"

  clone = {
    source_vm_id = 9000
    full         = true
  }
}
