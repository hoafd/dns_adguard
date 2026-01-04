# 🛡️ DNS AdGuard Master (Recursive & Secure)

Hệ thống DNS cá nhân chặn quảng cáo mạnh mẽ, tích hợp **AdGuard Home** và **Unbound**. Giải pháp này giúp tối ưu hóa tốc độ truy cập, bảo vệ quyền riêng tư và lọc nội dung độc hại trên toàn bộ hệ thống mạng của bạn.

---

## 🌟 Tính năng nổi bật

* **Chặn quảng cáo tầng DNS:** Sử dụng AdGuard Home để lọc hàng triệu tên miền quảng cáo/theo dõi.
* **Truy vấn đệ quy (Recursive DNS):** Tích hợp Unbound để tự phân giải DNS từ Root Servers, không phụ thuộc vào Google hay Cloudflare.
* **Bảo mật SSL:** Hỗ trợ tự động cấp và gia hạn chứng chỉ Let's Encrypt qua Cloudflare API.
* **Vận hành an toàn:** Cổng quản trị được ẩn sau Cloudflare Tunnel, chỉ mở cổng 53 (DNS) cho truy vấn công cộng.
* **Tối ưu RAM:** Script tự động tính toán dung lượng Cache phù hợp cho hệ thống (Hỗ trợ mức 256MB - 768MB).

---

## 🛠️ Hướng dẫn cài đặt nhanh

Sao chép và dán lệnh dưới đây vào Terminal của bạn:

```bash
curl -sSL [https://raw.githubusercontent.com/hoafd/dns_adguard/main/dns_setup.sh](https://raw.githubusercontent.com/hoafd/dns_adguard/main/dns_setup.sh) | sudo -E bash
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

---

## ⚖️ Giấy phép
Dự án được cấp phép theo **MIT License**. Copyright (c) 2026.
