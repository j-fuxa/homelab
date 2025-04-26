# Ubuntu Server Noble (24.04.x) + Docker
# ---
# Packer Template to create an Ubuntu Server (Noble 24.04.x) + Docker on Proxmox

variable "proxmox_api_url" {
    type = string
    description = "URL for Proxmox API endpoint"
}

variable "proxmox_api_token_id" {
    type = string
    description = "Proxmox API token ID"
}

variable "proxmox_api_token_secret" {
    type = string
    sensitive = true
    description = "Proxmox API token secret"
}

source "proxmox-iso" "ubuntu-server-noble" {
    # Proxmox Connection Settings
    proxmox_url = "${var.proxmox_api_url}"
    username = "${var.proxmox_api_token_id}"
    token = "${var.proxmox_api_token_secret}"
    # Uncomment if using self-signed certificates
    # insecure_skip_tls_verify = true

    # VM General Settings
    node = "prx-dev-1"
    vm_id = "90002"
    vm_name = "ubuntu-server-noble-docker"
    template_description = "Ubuntu Server Noble (24.04) x86_64 + Docker template built with packer on ${formatdate("YYYY-MM-DD hh:mm:ss ZZZ", timestamp())}"

    boot_iso {
        type = "scsi"
        iso_file = "local:iso/ubuntu-24.04.2-live-server-amd64.iso"
        # iso_url = "https://releases.ubuntu.com/24.04.2/ubuntu-24.04.2-live-server-amd64.iso"
        iso_checksum = "sha256:d6dab0c3a657988501b4bd76f1297c053df710e06e0c3aece60dead24f270b4d"
        unmount = true
    }

    qemu_agent = true

    scsi_controller = "virtio-scsi-pci"
    disks {
        disk_size = "20G"
        format = "raw"
        storage_pool = "local-lvm"
        type = "virtio"
    }

    cores = "1"
    memory = "2048"

    # VM Network Settings
    network_adapters {
        model = "virtio"
        bridge = "vmbr0"
        firewall = "false"
    }

    cloud_init = true
    cloud_init_storage_pool = "local-lvm"

    boot_command = [
        "<esc><wait>",
        "e<wait>",
        "<down><down><down><end>",
        "<bs><bs><bs><bs><wait>",
        "autoinstall ds=nocloud-net\\;s=http://{{ .HTTPIP }}:{{ .HTTPPort }}/ ---<wait>",
        "<f10><wait>"
    ]

    boot = "c"
    boot_wait = "10s"

    communicator = "ssh"
    http_directory = "http"
    ssh_username = "ubuntu"
    ssh_password = "cloud"
    ssh_timeout = "30m"
    ssh_pty = true
}

build {
    name = "ubuntu-server-noble-docker"
    sources = ["source.proxmox-iso.ubuntu-server-noble"]

    provisioner "shell" {
        inline = [
            "while [ ! -f /var/lib/cloud/instance/boot-finished ]; do echo 'Waiting for cloud-init...'; sleep 1; done",
            "sudo rm /etc/ssh/ssh_host_*",
            "sudo truncate -s 0 /etc/machine-id",
            "sudo apt -y autoremove --purge",
            "sudo apt -y clean",
            "sudo apt -y autoclean",
            "sudo cloud-init clean",
            "sudo rm -f /etc/cloud/cloud.cfg.d/subiquity-disable-cloudinit-networking.cfg",
            "sudo rm -f /etc/netplan/00-installer-config.yaml",
            "sudo sync"
        ]
    }

    provisioner "file" {
        source = "files/99-pve.cfg"
        destination = "/tmp/99-pve.cfg"
    }

    provisioner "shell" {
        inline = ["sudo cp /tmp/99-pve.cfg /etc/cloud/cloud.cfg.d/99-pve.cfg"]
    }

        provisioner "shell" {
        inline = [
            "sudo apt-get install -y ca-certificates curl gnupg lsb-release",
            "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg",
            "echo \"deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable\" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null",
            "sudo apt-get -y update",
            "sudo apt-get install -y docker-ce docker-ce-cli containerd.io"
        ]
    }
}
