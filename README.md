# 🛡️ DNS AdGuard Master (Recursive & Secure)

[![English](https://img.shields.io/badge/Language-English-blue?style=flat-square)](#-english-version)
[![Tiếng Việt](https://img.shields.io/badge/Ngôn%20ngữ-Tiếng%20Việt-red?style=flat-square)](#-phiên-bản-tiếng-việt)

---

<a name="-english-version"></a>
## 🇬🇧 English Version

An optimized personal DNS system featuring powerful ad-blocking and recursive resolution. Integrated with Cloudflare Zero Trust security and automated Let's Encrypt SSL renewal.

### 🌟 Key Features

* **Recursive DNS:** Uses **Unbound** to query Root Servers directly, enhancing privacy by eliminating reliance on third-party DNS providers.
* **Auto-SSL:** Automated issuance and renewal of **Let's Encrypt** certificates via Cloudflare API. The script automatically mounts certificates into the Docker container.
* **Firewall (UFW):** Automatically configures essential ports: `53` (DNS), Custom Admin Port, and `80/443` (SSL).
* **Health Check:** Dedicated script to monitor Container status and real-world resolution capabilities.
* **Flexibility:** Options to customize the Admin Port and Unbound RAM allocation during installation.

### 🛠️ Quick Installation

Run the following command for automatic installation on **Ubuntu 22.04/24.04**:

```bash
curl -sSL https://raw.githubusercontent.com/hoafd/dns_adguard/main/install_manager.sh | sudo -E bash
```

**Note:** Ensure you have your Cloudflare API Token ready if you intend to use SSL.

### ⚙️ Post-Installation Configuration

After installation, access `http://<Your-IP>:<CHOSEN_PORT>` (Default port is 3000) to setup AdGuard Home.

#### 1. Connect AdGuard to Unbound
To use the recursive DNS capabilities:
1.  Go to **Settings** -> **DNS Settings**.
2.  In **Upstream DNS servers**, enter:
    ```
    127.0.0.1:5335
    ```
3.  Select **Parallel requests**.
4.  Click **Apply**.

#### 2. Enable Encryption (SSL/HTTPS)
If you selected `y` for SSL installation in the script, the certificates are already mounted.

1.  Go to **Settings** -> **Encryption settings**.
2.  Check **Enable encryption**.
3.  **Server name:** Enter your domain (e.g., `dns.yourdomain.com`).
4.  **HTTPS port:** Set to `443`.
5.  **Certificates:**
    * **Certificate path:**
        ```
        /etc/letsencrypt/live/YOUR_DOMAIN_HERE/fullchain.pem
        ```
    * **Private key path:**
        ```
        /etc/letsencrypt/live/YOUR_DOMAIN_HERE/privkey.pem
        ```
    *(Replace `YOUR_DOMAIN_HERE` with the actual domain you entered during installation).*

### 🔄 Maintenance & Tools

| Action | Command |
| :--- | :--- |
| **Check Health** | `curl -sSL https://raw.githubusercontent.com/hoafd/dns_adguard/main/check_dns_health.sh | bash` |
| **Update/Reconfig** | `curl -sSL https://raw.githubusercontent.com/hoafd/dns_adguard/main/install_manager.sh | sudo -E bash` |
| **Uninstall** | `curl -sSL https://raw.githubusercontent.com/hoafd/dns_adguard/main/dns_uninstall.sh | sudo bash` |

---

<a name="-phiên-bản-tiếng-việt"></a>
## 🇻🇳 Phiên bản Tiếng Việt

Hệ thống DNS cá nhân tối ưu hóa, tích hợp chặn quảng cáo mạnh mẽ và phân giải đệ quy (Recursive DNS). Tự động hóa bảo mật với Cloudflare Zero Trust và chứng chỉ SSL Let's Encrypt.

### 🌟 Tính năng nổi bật

* **Recursive DNS:** Sử dụng **Unbound** để truy vấn trực tiếp đến Root Servers, tăng tính riêng tư và không phụ thuộc vào các nhà cung cấp DNS thứ ba (như Google/Cloudflare).
* **Auto-SSL:** Tự động xin và gia hạn chứng chỉ **Let's Encrypt** qua Cloudflare API. Script tự động "mount" chứng chỉ vào Docker container.
* **Tường lửa (UFW):** Tự động mở các cổng cần thiết: `53` (DNS), Cổng Admin tùy chỉnh, và `80/443` (SSL).
* **Tùy biến cao:** Cho phép chọn cổng giao diện quản lý và dung lượng RAM cho Unbound ngay khi cài đặt.

### 🛠️ Hướng dẫn cài đặt nhanh

Chạy lệnh sau để cài đặt tự động trên **Ubuntu 22.04/24.04**:

```bash
curl -sSL https://raw.githubusercontent.com/hoafd/dns_adguard/main/install_manager.sh | sudo -E bash
```

**Lưu ý:** Chuẩn bị sẵn Cloudflare API Token nếu bạn muốn cài đặt SSL.

### ⚙️ Cấu hình sau cài đặt

Sau khi cài đặt xong, truy cập `http://<IP-Cua-Ban>:<PORT>` (Mặc định là 3000) để thiết lập AdGuard Home.

#### 1. Kết nối AdGuard với Unbound
Để sử dụng tính năng phân giải đệ quy:
1.  Vào **Settings** -> **DNS Settings**.
2.  Tại mục **Upstream DNS servers**, nhập:
    ```
    127.0.0.1:5335
    ```
3.  Chọn chế độ **Parallel requests**.
4.  Nhấn **Apply**.

#### 2. Kích hoạt Mã hóa (SSL/HTTPS)
Nếu bạn đã chọn `y` ở bước cài SSL trong script, chứng chỉ đã được đưa vào container. Làm theo các bước sau:

1.  Vào **Settings** -> **Encryption settings**.
2.  Tích chọn **Enable encryption**.
3.  **Server name:** Nhập tên miền của bạn (ví dụ: `dns.hoafd.id.vn`).
4.  **HTTPS port:** Điền `443`.
5.  **Certificates (Chứng chỉ):**
    * **Certificate path (Đường dẫn chứng chỉ):**
        ```
        /etc/letsencrypt/live/TEN_MIEN_CUA_BAN/fullchain.pem
        ```
    * **Private key path (Đường dẫn khóa riêng):**
        ```
        /etc/letsencrypt/live/TEN_MIEN_CUA_BAN/privkey.pem
        ```
    *(Thay thế `TEN_MIEN_CUA_BAN` bằng tên miền thực tế bạn đã nhập khi chạy script).*
6.  Nhấn **Save config**.

### 🔄 Công cụ & Bảo trì

| Hành động | Lệnh thực thi |
| :--- | :--- |
| **Kiểm tra trạng thái** | `curl -sSL https://raw.githubusercontent.com/hoafd/dns_adguard/main/check_dns_health.sh | bash` |
| **Cập nhật / Cấu hình lại** | `curl -sSL https://raw.githubusercontent.com/hoafd/dns_adguard/main/install_manager.sh | sudo -E bash` |
| **Gỡ cài đặt** | `curl -sSL https://raw.githubusercontent.com/hoafd/dns_adguard/main/dns_uninstall.sh | sudo bash` |

---

## ☕ Support my work / Ủng hộ tác giả

If this project helps you, please consider supporting me with a coffee:
Nếu dự án này giúp ích cho bạn, hãy mời mình một ly cà phê nhé:

[![Buy Me A Coffee](https://img.shields.io/badge/Buy%20Me%20A%20Coffee-Donate-orange?style=for-the-badge&logo=buy-me-a-coffee&logoColor=white)](https://www.buymeacoffee.com/hoa0290303s)

## ⚖️ License

This project is licensed under the [MIT License](LICENSE). Copyright (c) 2026 **hoafd**.
