# 🛡️ DNS AdGuard Master (Recursive & Secure)

An optimized personal DNS system featuring powerful ad-blocking and recursive resolution. Integrated with Cloudflare Zero Trust security and automated Let's Encrypt SSL renewal.

## 🌟 Key Features

* **Recursive DNS:** Uses **Unbound** to query Root Servers directly, enhancing privacy by eliminating reliance on third-party DNS providers.
* **Auto-SSL:** Automated issuance and renewal of **Let's Encrypt** certificates via Cloudflare API. Includes a Deploy Hook to automatically restart AdGuard upon certificate renewal.
* **Firewall (UFW):** Automatically configures essential ports: `53` (DNS), Custom Admin Port, and `80/443` (SSL).
* **Health Check:** Dedicated script to monitor Container status and real-world resolution capabilities.
* **Flexibility:** Options to customize the Admin Port and Unbound RAM allocation during installation.

## 📋 System Requirements

* **Operating System:** Ubuntu 24.04 LTS (Recommended), Ubuntu 22.04, Debian 12.
* **Hardware:** Architecture x86_64 or ARM64 (Raspberry Pi). Minimum 512MB RAM (768MB+ Recommended).
* **Cloudflare (Required):**
    * **API Token:** Permission `Zone:DNS:Edit` for SSL validation.
    * **Tunnel Token:** For secure remote access.
    * **Domain:** A domain managed on Cloudflare.

## 📂 System Directory Structure

Persistent Data is stored at:

* **Root Directory:** `/opt/server-central/dns/`
* **Unbound Config:** `./unbound/unbound.conf`
* **AdGuard Data:** `./adguard/conf/` and `./adguard/work/`
* **SSL Certificates:** `/etc/letsencrypt/live/<your-domain>/`

## 🛠️ Quick Installation Guide

Run the following command for automatic installation:

```bash
curl -sSL [https://raw.githubusercontent.com/hoafd/dns_adguard/main/dns_setup.sh](https://raw.githubusercontent.com/hoafd/dns_adguard/main/dns_setup.sh) | sudo -E bash
```

**Note:** Ensure you have your Cloudflare API Token and Tunnel Token ready before running the script.

---

### ⚙️ Post-Installation Configuration

After installation, follow these steps to finalize the setup:

1.  **Initial Setup:** Access `http://<Your-IP>:<CHOSEN_PORT>` to complete AdGuard Home configuration.
2.  **SSL Setup:** In Web UI -> **Settings** -> **Encryption settings**, point the certificate paths to `/etc/letsencrypt/live/...`.
3.  **Connect Unbound:** In **DNS Settings** -> **Upstream DNS**, enter: `127.0.0.1:5335`.

## 🩺 System Health Check

Use the following script to check Container status and DNS resolution performance:

```bash
curl -sSL [https://raw.githubusercontent.com/hoafd/dns_adguard/main/check_dns_health.sh](https://raw.githubusercontent.com/hoafd/dns_adguard/main/check_dns_health.sh) | bash
```

## 🔄 Updates & Maintenance

### 🚀 Safe Update
Use this to fetch the latest AdGuard/Unbound versions without changing Ports or RAM settings.

```bash
curl -sSL [https://raw.githubusercontent.com/hoafd/dns_adguard/main/dns_update.sh](https://raw.githubusercontent.com/hoafd/dns_adguard/main/dns_update.sh) | sudo bash
```

### ⚙️ Re-configure
Use this to change the Admin Port, allocate more RAM, or reinstall SSL certificates.

```bash
curl -sSL [https://raw.githubusercontent.com/hoafd/dns_adguard/main/dns_setup.sh](https://raw.githubusercontent.com/hoafd/dns_adguard/main/dns_setup.sh) | sudo -E bash
```

## ☕ Support my work

If this project helps you, please consider supporting me with a coffee:

[![Buy Me A Coffee](https://img.shields.io/badge/Buy%20Me%20A%20Coffee-Donate-orange?style=for-the-badge&logo=buy-me-a-coffee&logoColor=white)](https://www.buymeacoffee.com/hoa0290303s)

## ⚖️ License

This project is licensed under the [MIT License](LICENSE). Copyright (c) 2026 **hoafd**.
