# 🛡️ DNS AdGuard Master (Recursive & Secure)

Hệ thống DNS cá nhân tối ưu, chặn quảng cáo mạnh mẽ và phân giải đệ quy. Tích hợp sẵn cơ chế bảo mật Cloudflare Zero Trust và tự động gia hạn SSL.

---

## 🌟 Tính năng nổi bật
* **Recursive DNS:** Sử dụng Unbound tự truy vấn Root Servers, không phụ thuộc vào các DNS bên thứ ba.
* **Auto-SSL:** Cấp và gia hạn Let's Encrypt qua Cloudflare API, tự động **Restart AdGuard** khi có chứng chỉ mới thông qua Deploy Hook.
* **Firewall (UFW):** Tự động cấu hình mở cổng 53 (DNS), 3000 (Setup), 80/443 (SSL) và bảo vệ các cổng hệ thống khác.
* **Health Check:** Script chuyên dụng để kiểm tra sức khỏe hệ thống từ trạng thái Container đến khả năng chặn thực tế.
* **Tính năng: Tùy chọn cổng quản trị (Admin Port) và tự động cấu hình tường lửa (ufw).

---

## 📋 Yêu cầu hệ thống (System Requirements)

Để hệ thống vận hành ổn định và tự động hóa hoàn toàn, bạn cần chuẩn bị:

### 1. Phần cứng & Hệ điều hành
## 💻 Khả năng tương thích (Compatibility)

Hệ thống này được thiết kế và kiểm thử tối ưu cho:
* **Hệ điều hành:** Ubuntu 24.04 LTS (Khuyên dùng), Ubuntu 22.04, Debian 12.
* **Kiến trúc CPU:** x86_64 (PC/Server), ARM64 (Raspberry Pi 4/5).

**Lưu ý:** Nếu sử dụng trên các hệ điều hành không dựa trên Debian (như CentOS, Fedora), bạn cần cài đặt thủ công các gói phụ thuộc thay vì sử dụng script setup tự động.

* **RAM:** Tối thiểu 512MB (Khuyên dùng **768MB** để tối ưu bộ nhớ đệm Unbound).
* **Docker:** Đã cài đặt Docker và Docker Compose.

### 2. Cấu hình Cloudflare (Bắt buộc cho SSL & Remote Access)
Vì hệ thống sử dụng phương thức **DNS-01 Challenge** để cấp SSL và **Zero Trust** để truy cập từ xa, bạn cần:
* **Cloudflare API Token:** Quyền `Zone:DNS:Edit` (Dùng để xác thực cấp chứng chỉ SSL Let's Encrypt).
* **Cloudflare Tunnel Token:** Để vận hành dịch vụ `cloudflared`, giúp truy cập trang quản trị an toàn mà không cần mở Port.
* **Domain:** Tên miền đã được trỏ về NameServer của Cloudflare.

---

## 📂 Cấu trúc thư mục hệ thống
* **Thư mục gốc:** `/opt/server-central/dns/`
* **Cấu hình Unbound:** `./unbound/unbound.conf` (Mount vào `/opt/unbound/etc/unbound/`)
* **Dữ liệu AdGuard:** * `./adguard/conf/` (File cấu hình AdGuardHome.yaml)
    * `./adguard/work/` (Dữ liệu lọc, Database và Logs)
* **Đường dẫn SSL (Host):** `/etc/letsencrypt/live/<your-domain>/` (Mount Read-only vào Docker)

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
