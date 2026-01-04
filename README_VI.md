# 🛡️ DNS AdGuard Master (Recursive & Secure)

Hệ thống DNS cá nhân tối ưu, chặn quảng cáo mạnh mẽ và phân giải đệ quy. Tích hợp sẵn cơ chế bảo mật Cloudflare Zero Trust và tự động gia hạn SSL Let's Encrypt.

## 🌟 Tính năng nổi bật

* **Recursive DNS:** Sử dụng **Unbound** tự truy vấn Root Servers, tăng tính riêng tư, không phụ thuộc vào DNS bên thứ ba.
* **Auto-SSL:** Tự động cấp và gia hạn **Let's Encrypt** qua Cloudflare API. Tích hợp Deploy Hook để tự động khởi động lại AdGuard khi có chứng chỉ mới.
* **Firewall (UFW):** Tự động cấu hình mở các cổng thiết yếu: `53` (DNS), Cổng quản trị tùy chỉnh, `80/443` (SSL).
* **Health Check:** Script chuyên dụng kiểm tra trạng thái Container và khả năng phân giải thực tế của hệ thống.
* **Linh hoạt:** Tùy chọn cổng quản trị (Admin Port) và mức cấp phát RAM cho Unbound ngay khi cài đặt.

## 📋 Yêu cầu hệ thống

* **Hệ điều hành:** Ubuntu 24.04 LTS (Khuyên dùng), Ubuntu 22.04, Debian 12.
* **Phần cứng:** Kiến trúc x86_64 hoặc ARM64 (Raspberry Pi). RAM tối thiểu 512MB (Khuyên dùng 768MB+).
* **Cloudflare (Bắt buộc):**
    * **API Token:** Quyền `Zone:DNS:Edit` để xác thực SSL.
    * **Tunnel Token:** Để truy cập an toàn từ xa.
    * **Domain:** Tên miền đã được quản lý trên Cloudflare.

## 📂 Cấu trúc thư mục hệ thống

Dữ liệu được lưu trữ bền vững tại:

* **Thư mục gốc:** `/opt/server-central/dns/`
* **Cấu hình Unbound:** `./unbound/unbound.conf`
* **Dữ liệu AdGuard:** `./adguard/conf/` và `./adguard/work/`
* **Chứng chỉ SSL:** `/etc/letsencrypt/live/<your-domain>/`

## 🛠️ Hướng dẫn cài đặt nhanh

Chạy lệnh sau để cài đặt tự động:

```bash
curl -sSL https://raw.githubusercontent.com/hoafd/dns_adguard/main/dns_setup.sh | sudo -E bash
```

**Lưu ý:** Bạn cần chuẩn bị sẵn Cloudflare API Token và Tunnel Token trước khi chạy script.

---

### ⚙️ Cấu hình sau cài đặt

Sau khi cài đặt xong, hãy thực hiện các bước sau để hoàn tất:

1.  **Thiết lập ban đầu:** Truy cập `http://<IP_Của_Bạn>:<PORT_ĐÃ_CHỌN>` để cài đặt AdGuard Home.
2.  **Cài đặt SSL:** Tại giao diện Web -> **Settings** -> **Encryption settings**, trỏ đường dẫn chứng chỉ tới `/etc/letsencrypt/live/...`.
3.  **Kết nối Unbound:** Tại mục **DNS Settings** -> **Upstream DNS**, điền: `127.0.0.1:5335`.

## 🩺 Kiểm tra sức khỏe hệ thống

Sử dụng script sau để kiểm tra trạng thái Container và khả năng phân giải DNS:

```bash
curl -sSL https://raw.githubusercontent.com/hoafd/dns_adguard/main/check_dns_health.sh | bash
```

### ### 🗑️ Uninstall
```bash
curl -sSL https://raw.githubusercontent.com/hoafd/dns_adguard/main/dns_uninstall.sh | sudo bash
```
---
## 🔄 Cập nhật & Bảo trì

### 🚀 Cập nhật nhanh (Safe Update)
Dùng khi bạn chỉ muốn tải phiên bản AdGuard/Unbound mới nhất mà không thay đổi Port hay RAM.

```bash
curl -sSL [https://raw.githubusercontent.com/hoafd/dns_adguard/main/dns_update.sh](https://raw.githubusercontent.com/hoafd/dns_adguard/main/dns_update.sh) | sudo bash
```

### ⚙️ Cài đặt lại (Re-configure)
Dùng khi bạn muốn đổi cổng quản trị, cấp thêm RAM hoặc cài lại chứng chỉ SSL.

```bash
curl -sSL [https://raw.githubusercontent.com/hoafd/dns_adguard/main/dns_setup.sh](https://raw.githubusercontent.com/hoafd/dns_adguard/main/dns_setup.sh) | sudo -E bash
```

## ☕ Support my work

Nếu dự án này giúp ích cho bạn, hãy ủng hộ tôi một ly cà phê tại:

[![Buy Me A Coffee](https://img.shields.io/badge/Buy%20Me%20A%20Coffee-Donate-orange?style=for-the-badge&logo=buy-me-a-coffee&logoColor=white)](https://www.buymeacoffee.com/hoa0290303s)

## ⚖️ Giấy phép

Dự án được cấp phép theo [MIT License](LICENSE). Copyright (c) 2026 **hoafd**.
