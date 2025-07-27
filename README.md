# 🥷 kage-cli

**kage-cli** is a powerful and minimalist shell script that makes it easy to create, start, access, and stop virtual machines on DigitalOcean via `doctl`, with a focus on automation and FinOps practices.

---

## 📦 Overview

This CLI is designed for teams seeking **operational efficiency**, cost control, and simplicity in droplet management. Inspired by the Kage (影, *shadow*) philosophy, it operates discreetly, quickly, and accurately, ideal for DevOps and infrastructure engineers who need to scale snapshots on demand.

---

## 🚀 Features

- 📸 Optimized snapshot creation
- 🔁 Machine startup and shutdown
- 🐚 Remote access via SSH
- 🧮 Ideal for FinOps routines and temporary environments

---

## ⚙️ Prerequisites

- [`doctl`](https://docs.digitalocean.com/reference/doctl/) installed and authenticated.  
- Valid DigitalOcean access token.  
> https://docs.digitalocean.com/reference/api/create-personal-access-token/  
---

## 🔐 Configuration

Authenticate your environment with:
> https://docs.digitalocean.com/reference/doctl/  
```bash
doctl auth init --access-token dop_v1_ed51[...]
```
Adjust the machine settings at the beginning of the script:  
> https://slugs.do-api.dev/  
```bash
# Configurações fixas
# https://slugs.do-api.dev/
REGION="nyc3"
SIZE="s-8vcpu-16gb"
IMAGE="debian-12-x64"
TAG="kage-cli,pentest"
WAIT="--wait"
```

---

## 🧰 Usage

```bash
# Create a machine snapshot
./kage-cli.sh create machine <machine_name>

# Start a machine
./kage-cli.sh start machine <machine_name>

# Connect via SSH
./kage-cli.sh ssh machine <machine_name>

# Stop the machine
./kage-cli.sh stop machine <machine_name>
```

Replace `<machine_name>` with your droplet ID.

---

## 💡 Examples

```bash
./kage-cli.sh create machine Utumno
./kage-cli.sh start machine Utumno
./kage-cli.sh ssh machine Utumno
./kage-cli.sh stop machine Utumno
```
```bash
frog@Myoboku DigitalOcean % doctl compute snapshot list
ID           Name                           Created at              Regions    Resource ID    Resource Type    Min Disk Size    Size         Tags
194496640    Utumno-snapshot-1753475246     2025-07-25T20:27:28Z    [nyc3]     509958314      droplet          320              45.80 GiB    
```
```bash
frog@Myoboku DigitalOcean % doctl compute droplet list 
ID    Name    Public IPv4    Private IPv4    Public IPv6    Memory    VCPUs    Disk    Region    Image    VPC UUID    Status    Tags    Features    Volumes
```
---

## 🧠 Philosophy

> "The best infrastructure is invisible to the eye."
> — A FinOps ninja.

This script follows the pay-as-you-go mentality, helping you pay only for what you use, shutting down idle resources, and automatically optimizing snapshots.

---

## 📜 License

Distributed under the MIT license. See `LICENSE` for more details.

---

## 🤝 Contributing

Contributions are welcome! Feel free to open issues or PRs.

---

## 📬 Contact

For questions or suggestions, please contact us via [Issues](https://github.com/seurepo/kage-cli/issues).
