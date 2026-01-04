# 🛡️ DNS AdGuard Master

Hệ thống DNS chặn quảng cáo bảo mật cao tích hợp **AdGuard Home** và **Unbound**, được tối ưu hóa đặc biệt cho hiệu suất và bảo mật trên **Ubuntu 24.04**.

---

## 📋 Điều kiện hệ thống chạy

* **Hệ điều hành**: Ubuntu 24.04 LTS hoặc Debian 11/12.
* **Bộ nhớ (RAM)**: Tối thiểu 512MB RAM trống.
* **Mạng & Cổng**:
    * Cổng **53**: Phải sẵn dụng (Script sẽ tự động giải phóng khỏi systemd-resolved).
    * Cổng **22**: Mở để quản trị SSH.
    * Cổng **3000**: Giữ nội bộ (Truy cập qua Cloudflare Tunnel).
* **Quyền hạn**: Cần quyền `sudo`.

---

## 🛠️ Hướng dẫn cài đặt nhanh

Sao chép và dán lệnh dưới đây vào Terminal của bạn:

```bash
curl -sSL https://raw.githubusercontent.com/hoafd/dns_adguard/main/dns_setup.sh | sudo -E bash
```

---

## ⚙️ Thiết lập sau cài đặt

1. **Cloudflare Zero Trust**: Trỏ **Public Hostname** về `http://localhost:3000`.
2. **DNS Upstream**: Trong AdGuard Home, thiết lập Upstream là `127.0.0.1:5335`.
3. **Bảo mật**: Chỉ có cổng 22 và 53 được mở công khai qua UFW.

---

## ⚖️ Giấy phép (License)
Dự án được cấp phép theo [MIT License](LICENSE). Copyright (c) 2026 **hoafd**.
