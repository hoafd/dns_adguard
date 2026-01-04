# 🛡️ DNS AdGuard Master (Recursive & Secure)

Hệ thống DNS cá nhân chặn quảng cáo mạnh mẽ, tích hợp **AdGuard Home** và **Unbound**. Giải pháp này giúp tối ưu hóa tốc độ truy cập, bảo vệ quyền riêng tư và lọc nội dung độc hại trên toàn bộ hệ thống mạng của bạn.

---

## 🌟 Tính năng nổi bật
- **Recursive DNS:** Unbound tự truy vấn đến các Root Servers, không phụ thuộc vào DNS bên thứ ba.
- **Auto-SSL:** Cấp chứng chỉ Let's Encrypt qua Cloudflare API, tự động gia hạn và khởi động lại AdGuard khi có chứng chỉ mới.
- **Tối ưu RAM:** Script tự động cấu hình bộ nhớ đệm (Cache) dựa trên RAM thực tế của máy chủ.
- **Health Check:** Có script kiểm tra sức khỏe hệ thống (Container, Port, Khả năng chặn thực tế).
- **Firewall:** Tự động cấu hình UFW bảo vệ các cổng nhạy cảm.

---

## 📂 Cấu trúc thư mục hệ thống
Mọi dữ liệu được lưu trữ tập trung tại máy chủ ở đường dẫn:
- **Thư mục gốc:** `/opt/server-central/dns/`
- **Cấu hình Unbound:** `./unbound/unbound.conf`
- **Dữ liệu AdGuard:** - `./adguard/conf/` (Chứa file AdGuardHome.yaml)
  - `./adguard/work/` (Chứa Database và logs)
- **Chứng chỉ SSL:** `/etc/letsencrypt/live/<domain-cua-ban>/` (Được mount vào Docker)

---

## 🛠️ Hướng dẫn cài đặt nhanh

Sao chép và dán lệnh dưới đây vào Terminal của bạn:

```bash
curl -sSL https://raw.githubusercontent.com/hoafd/dns_adguard/main/dns_setup.sh | sudo -E bash
```

---

## ⚙️ Cấu hình sau cài đặt

### 1. Thiết lập ban đầu (Setup Wizard)
Sau khi cài đặt, hãy truy cập `http://<IP_Server_cua_ban>:3000` để hoàn tất cấu hình AdGuard Home.

### 2. Cài đặt SSL cho Dashboard
Tại giao diện Web AdGuard -> **Settings** -> **Encryption settings**:
* **Server Name:** `domain-cua-ban.com`
* **Certificate path:** `/etc/letsencrypt/live/domain-cua-ban.com/fullchain.pem`
* **Private key path:** `/etc/letsencrypt/live/domain-cua-ban.com/privkey.pem`

### 3. Kết nối Unbound
Tại mục **Settings** -> **DNS Settings** -> **Upstream DNS servers**, điền:
`127.0.0.1:5335`

## 🩺 Kiểm tra sức khỏe hệ thống

Để đảm bảo các Container và bộ lọc đang hoạt động đúng cách, bạn có thể chạy script kiểm tra nhanh:

```bash
curl -sSL https://raw.githubusercontent.com/hoafd/dns_adguard/main/check_dns_health.sh | bash
```

---

## ⚖️ Giấy phép
Dự án được cấp phép theo [MIT License](LICENSE). Copyright (c) 2026 **hoafd**.
