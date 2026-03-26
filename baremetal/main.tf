resource "aws_security_group" "metal_sg" {
  name        = "metal3-sg"
  description = "Metal3 bare metal emulation host"
  vpc_id      = data.aws_vpc.vpc.id

  ingress {
    description = "All from VPC"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.vpc.cidr_block]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "metal3-sg"
  }
}

# Primary ENI — sushy + management traffic
resource "aws_network_interface" "primary" {
  subnet_id         = var.subnet_id
  security_groups   = [aws_security_group.metal_sg.id]
  source_dest_check = false

  tags = {
    Name = "metal3-primary"
  }
}

# One ENI per VM — gets a real VPC IP, bridged via macvtap
resource "aws_network_interface" "worker" {
  count             = 3
  subnet_id         = var.subnet_id
  security_groups   = [aws_security_group.metal_sg.id]
  source_dest_check = false

  tags = {
    Name = "metal3-worker-${count.index + 1}"
  }
}

resource "aws_instance" "metal_node" {
  ami                  = data.aws_ami.metal_node.id
  instance_type        = "m5.metal"
  iam_instance_profile = var.iam_instance_profile_name

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required" # this enforces IMDSv2
    http_put_response_hop_limit = 2          # 1 is default, 2 needed for containers/VMs on the host
    instance_metadata_tags      = "enabled"
  }

  # Primary network interface
  network_interface {
    network_interface_id = aws_network_interface.primary.id
    device_index         = 0
  }

  # Worker ENIs
  network_interface {
    network_interface_id = aws_network_interface.worker[0].id
    device_index         = 1
  }

  network_interface {
    network_interface_id = aws_network_interface.worker[1].id
    device_index         = 2
  }

  network_interface {
    network_interface_id = aws_network_interface.worker[2].id
    device_index         = 3
  }

  root_block_device {
    volume_size           = 50
    volume_type           = "gp3"
    delete_on_termination = true
  }

  ebs_block_device {
    device_name           = "/dev/xvdf"
    volume_size           = 100
    volume_type           = "gp3"
    delete_on_termination = true
  }

  user_data = base64encode(<<-EOL
    #!/bin/bash
    set -euxo pipefail
    exec >> /var/log/metal3-bootstrap.log 2>&1

    # Install packages
    yum install -y \
      qemu-kvm \
      libvirt \
      libvirt-client \
      virt-install \
      bridge-utils \
      iproute-tc \
      python3-pip \
      cloud-utils \
      gcc \
      python3-devel \
      libvirt-devel \
      pkgconfig

    # Start libvirt
    systemctl enable --now libvirtd

    # Mount data volume FIRST
    if ! blkid /dev/nvme1n1 >/dev/null 2>&1; then
      mkfs.xfs -f /dev/nvme1n1
    fi
    mkdir -p /var/lib/libvirt/images
    if ! grep -qE '^/dev/nvme1n1[[:space:]]+/var/lib/libvirt/images[[:space:]]+xfs[[:space:]]' /etc/fstab; then
      echo '/dev/nvme1n1 /var/lib/libvirt/images xfs defaults 0 0' >> /etc/fstab
    fi
    mountpoint -q /var/lib/libvirt/images || mount /var/lib/libvirt/images

    # Create the default pool if it does not already exist.
    if ! virsh pool-info default >/dev/null 2>&1; then
      virsh pool-define-as default dir --target /var/lib/libvirt/images
      virsh pool-build default
    fi
    virsh pool-start default || true
    virsh pool-autostart default

    # verify
    virsh pool-list --all
    virsh pool-info default

    # Install pinned Python deps for reproducibility.
    pip3 install --no-cache-dir \
      'urllib3==1.26.20' \
      'sushy-tools==0.19.0' \
      'libvirt-python==12.1.0'

    # sushy config
    mkdir -p /etc/sushy
    cat > /etc/sushy/sushy.conf <<'SUSHYCONF'
SUSHY_EMULATOR_LIBVIRT_URI = "qemu:///system"
SUSHY_EMULATOR_IGNORE_BOOT_DEVICE = False
SUSHY_EMULATOR_LISTEN_IP = "0.0.0.0"
SUSHY_EMULATOR_LISTEN_PORT = 8000
SUSHY_EMULATOR_SSL_CERT = None
SUSHY_EMULATOR_SSL_KEY = None
SUSHY_EMULATOR_AUTH_FILE = None
SUSHYCONF

    cat > /etc/systemd/system/sushy-tools.service <<'SERVICECONF'
[Unit]
Description=sushy-tools Redfish emulator
After=libvirtd.service

[Service]
ExecStart=/usr/local/bin/sushy-emulator --config /etc/sushy/sushy.conf
Restart=always

[Install]
WantedBy=multi-user.target
SERVICECONF

    systemctl daemon-reload
    systemctl enable --now sushy-tools

    chmod 666 /dev/kvm

    cat > /usr/local/bin/metal3-create-vms.sh <<'VMBOOTSTRAP'
#!/bin/bash
set -euxo pipefail

modprobe macvtap
modprobe macvlan
modprobe tun
modprobe tap

systemctl is-active --quiet libvirtd || systemctl start libvirtd

# On EC2 ENA, libvirt direct passthrough cannot program MAC on the lower ENI.
# Use macvtap bridge mode with stable VM MACs, then rewrite L2 headers with tc
# so frames on-wire always use the ENI MAC required by AWS.
for i in 1 2 3; do
  ETH="eth$i"
  for _ in $(seq 1 90); do
    if ip link show "$ETH" >/dev/null 2>&1; then
      break
    fi
    sleep 1
  done
  ip link show "$ETH" >/dev/null 2>&1
  pkill -f "dhclient.*$ETH" || true
  dhclient -r "$ETH" >/dev/null 2>&1 || true
  ip addr flush dev "$ETH" || true
  ip -6 addr flush dev "$ETH" || true
  ip route flush dev "$ETH" || true
  ip -6 route flush dev "$ETH" || true
  ip link set "$ETH" down || true
  ip link set "$ETH" up
done

# Clean up stale macvtap/qemu from interrupted runs.
for link in $(ip -o link show type macvtap | awk -F': ' '{print $2}'); do
  ip link set "$link" down || true
  ip link del "$link" || true
done
pkill -f qemu-system-x86_64 || true
systemctl restart libvirtd

for i in 1 2 3; do
  VM="worker-$i"
  ETH="eth$i"
  VM_MAC=$(printf '52:54:00:aa:bb:%02x' "$i")
  ENI_MAC=$(ip link show "$ETH" | awk '/link\/ether/ {print $2; exit}')
  NEED_CREATE=1
  if [[ -z "$ENI_MAC" ]]; then
    echo "Missing MAC for $ETH" >&2
    exit 1
  fi

  if virsh dominfo "$VM" >/dev/null 2>&1; then
    EXISTING_MAC=$(virsh domiflist "$VM" | grep -Eo '([[:xdigit:]]{2}:){5}[[:xdigit:]]{2}' | head -1)
    if [[ "$EXISTING_MAC" != "$VM_MAC" ]]; then
      virsh destroy "$VM" >/dev/null 2>&1 || true
      virsh undefine "$VM" --remove-all-storage --nvram >/dev/null 2>&1 || true
    else
      NEED_CREATE=0
    fi
  fi

  if [[ "$NEED_CREATE" -eq 1 ]]; then
    for attempt in 1 2 3 4 5; do
      if virt-install \
        --name "$VM" \
        --ram 4096 \
        --vcpus 2 \
        --disk path="/var/lib/libvirt/images/$VM.qcow2",size=40,format=qcow2,bus=virtio \
        --os-variant generic \
        --noautoconsole \
        --graphics none \
        --video none \
        --cpu host \
        --boot hd,cdrom,network \
        --disk device=cdrom,bus=sata \
        --network type=direct,source="$ETH",source_mode=bridge,model=virtio,mac="$VM_MAC"; then
        break
      fi
      if [[ "$attempt" -eq 5 ]]; then
        echo "Failed to create $VM after $attempt attempts" >&2
        exit 1
      fi
      virsh destroy "$VM" >/dev/null 2>&1 || true
      virsh undefine "$VM" --remove-all-storage --nvram >/dev/null 2>&1 || true
      sleep 3
    done
  fi
done

for i in 1 2 3; do
  VM="worker-$i"
  ETH="eth$i"
  VM_MAC=$(virsh domiflist "$VM" | grep -Eo '([[:xdigit:]]{2}:){5}[[:xdigit:]]{2}' | head -1)
  ENI_MAC=$(ip link show "$ETH" | awk '/link\/ether/ {print $2; exit}')
  if [[ -z "$VM_MAC" || -z "$ENI_MAC" ]]; then
    echo "Missing MAC while applying tc rewrite for $VM/$ETH" >&2
    exit 1
  fi
  tc qdisc del dev "$ETH" clsact 2>/dev/null || true
  tc qdisc add dev "$ETH" clsact
  tc filter add dev "$ETH" egress protocol all flower \
    src_mac "$VM_MAC" \
    action pedit ex munge eth src set "$ENI_MAC"
  tc filter add dev "$ETH" ingress protocol all flower \
    dst_mac "$ENI_MAC" \
    action pedit ex munge eth dst set "$VM_MAC"
done
VMBOOTSTRAP

    chmod +x /usr/local/bin/metal3-create-vms.sh

    cat > /etc/systemd/system/metal3-create-vms.service <<'VMSERVICE'
[Unit]
Description=Create Metal3 worker VMs on dedicated ENIs
After=network-online.target libvirtd.service
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/metal3-create-vms.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
VMSERVICE

    systemctl daemon-reload
    systemctl enable --now metal3-create-vms.service
  EOL
  )

  tags = {
    Name         = "metal3-node"
    Team         = "Day0"
    DeployedBy   = "Stefan.Todorov@omniva.com"
    DeployMethod = "terraform"
    createdby    = "Stefan.Todorov@omniva.com"
    Environment  = local.env
    mde          = "protected"
  }
}
