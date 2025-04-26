# Proxmox VM Templates with Packer

This directory contains Packer configurations to build virtual machine templates for Proxmox.

## Available Templates

- **ubuntu-server-noble**: Ubuntu 24.04 LTS (Noble Numbat) server template
- **ubuntu-server-noble-docker**: Ubuntu 24.04 LTS (Noble Numbat) with Docker pre-installed

## Prerequisites

- [Packer](https://www.packer.io/downloads) (v1.8.0+)
- Proxmox VE server (tested with 8.0+)
- Proxmox API token with appropriate permissions
- Ubuntu 24.04 ISO uploaded to your Proxmox server

## Configuration

1. Copy the credentials sample file and fill in your Proxmox API information:

```bash
cp credentials.pkr.hcl.sample credentials.pkr.hcl
```

2. Edit `credentials.pkr.hcl` with your Proxmox API details:

## Building Templates

### Ubuntu Server (Noble)

```bash
cd ubuntu-server-noble
packer build -var-file="../credentials.pkr.hcl" ubuntu-server-noble.pkr.hcl
```

## Troubleshooting

- For SSL/TLS issues with self-signed certificates, uncomment the `insecure_skip_tls_verify = true` line
- If the build fails during SSH connection, increase the `ssh_timeout` value
- Ensure your Proxmox API token has sufficient privileges
