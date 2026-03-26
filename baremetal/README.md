# Bare metal emulation infrastructure setup
This TF module creates an AWS metal instance and emulates redfish BM hosts.
The purpose is to enable BMK8s provisioning without owning actual hardware.

## EC2 bootstrap behavior (Terraform user-data)

After `terraform apply`, user-data now does all bootstrap steps on the EC2 host:

1. Installs `qemu-kvm/libvirt/virt-install` and pinned Python deps:
   - `sushy-tools==0.19.0`
   - `libvirt-python==12.1.0`
   - `urllib3==1.26.20`
2. Starts `libvirtd`.
3. Mounts `/dev/nvme1n1` to `/var/lib/libvirt/images` and configures the libvirt `default` pool.
4. Configures and starts `sushy-emulator` on `0.0.0.0:8000` with:
   - `SUSHY_EMULATOR_IGNORE_BOOT_DEVICE = False`
5. Installs and starts `metal3-create-vms.service` (oneshot), which:
   - waits for `eth1..eth3`,
   - removes host-side DHCP/IP/routes from `eth1..eth3`,
   - creates `worker-1..3` with direct/macvtap `source_mode=bridge`,
   - applies `tc` MAC rewrite rules (`vm_mac <-> eni_mac`) per ENI.

No extra manual EC2 configuration is required after apply for the host bootstrap itself.

Important AWS ENA constraint:
- On `m5.metal` + AL2 ENA, libvirt/macvtap cannot set VM NIC MAC equal to ENI MAC directly:
  - direct passthrough path fails with `Cannot set interface MAC ... Operation not supported`
  - bridge path with same MAC fails with `Cannot set interface flags on 'macvtap0': Device or resource busy`
- Reproducible workaround is bridge mode + `tc` rewrite so AWS sees ENI MAC on wire while VM keeps a stable internal MAC.

## Post-apply verification (SSM)

Run in order:

```bash
sudo cloud-init status --long
sudo systemctl is-active libvirtd sushy-tools metal3-create-vms
sudo virsh list --all
sudo ss -lntp | grep ':8000'
```

Expected:
- cloud-init: done (no error)
- all 3 services active
- `worker-1..3` present in `virsh list --all` (running or shut off is acceptable)
- sushy bound on `0.0.0.0:8000`

VM/ENI mapping check:

```bash
for i in 1 2 3; do
  ENI_MAC=$(ip link show eth$i | awk '/link\/ether/ {print $2; exit}')
  VM_MAC=$(sudo virsh domiflist worker-$i | grep -Eo '([[:xdigit:]]{2}:){5}[[:xdigit:]]{2}' | head -1)
  echo "worker-$i eth$i eni=$ENI_MAC vm=$VM_MAC"
done
```

Expected:
- `eni` and `vm` are different.
- `tc` rewrite rules exist for each `eth1..eth3`:

```bash
for i in 1 2 3; do
  echo "=== eth$i egress ==="
  sudo tc filter show dev eth$i egress
  echo "=== eth$i ingress ==="
  sudo tc filter show dev eth$i ingress
done
```

BMH note:
- Use VM MACs (`virsh domiflist worker-*`) for `bootMACAddress`.
- Keep ENI MACs for host-side/network troubleshooting only.

Redfish systems check:

```bash
curl -s http://127.0.0.1:8000/redfish/v1/Systems | python3 -m json.tool
```

## Troubleshooting / reproducible rerun

If VM creation failed or you changed ENIs, rerun the same managed unit:

```bash
sudo systemctl restart metal3-create-vms
sudo systemctl status metal3-create-vms --no-pager -l
sudo journalctl -u metal3-create-vms -n 200 --no-pager
```

Bootstrap logs:

```bash
sudo tail -n 200 /var/log/metal3-bootstrap.log
```

Manual equivalent (only for debugging; service is preferred):

```bash
sudo /usr/local/bin/metal3-create-vms.sh
```

The EC2 commands used during troubleshooting (`aws ssm send-command`, `virt-cat`, `libguestfs-tools-c`) are diagnostic-only and are not part of required day-0 bootstrap.

```bash
echo "=== Summary for BMH manifests ==="
echo "Copy the following into your BareMetalHost specs:"
echo ""

SUSHY_IP=$(ip -4 addr show eth0 | awk '/inet /{print $2}' | cut -d/ -f1)

for i in 1 2 3; do
  VM="worker-$i"
  SYS_UUID=$(virsh domuuid "$VM")
  MAC=$(virsh domiflist "$VM" | awk '/virtio/ {print $5; exit}')
  echo "$VM:"
  echo "  bmc.address:     redfish-virtualmedia+http://${SUSHY_IP}:8000/redfish/v1/Systems/${SYS_UUID}"
  echo "  bootMACAddress:  $MAC"
  echo ""
done
```
