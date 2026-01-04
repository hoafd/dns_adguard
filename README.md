# 🛡️ DNS AdGuard Master

Hệ thống DNS chặn quảng cáo bảo mật cao tích hợp **AdGuard Home** và **Unbound**, được tối ưu hóa cho hiệu suất và bảo mật trên Ubuntu 24.04.

---

## 📋 Điều kiện hệ thống chạy

Để hệ thống hoạt động ổn định, máy chủ của bạn cần đáp ứng các yêu cầu sau:

* **Hệ điều hành**: Ubuntu 24.04 LTS (Khuyên dùng), Ubuntu 22.04, hoặc Debian 11/12.
* **Kiến trúc CPU**: x86_64 (amd64).
* **Bộ nhớ (RAM)**: 
    * Tối thiểu: 512MB RAM trống.
    * Khuyên dùng: 1GB RAM trở lên để tối ưu hóa bộ nhớ đệm (Cache) cho Unbound.
* **Kết nối mạng**:
    * Có kết nối Internet ổn định.
    * Cần có tài khoản Cloudflare và đã thiết lập **Cloudflare Zero Trust (Tunnel)**.
* **Yêu cầu về Cổng (Ports)**:
    * Cổng **53 (TCP/UDP)** phải sẵn dụng (Script sẽ tự động giải phóng nếu bị `systemd-resolved` chiếm giữ).
    * Cổng **22 (SSH)** để quản trị.
* **Phần mềm**: Yêu cầu quyền `sudo` hoặc `root` để cài đặt Docker và cấu hình hệ thống.

---

## 🛠️ Hướng dẫn cài đặt nhanh

```bash
curl -sSL [https://raw.githubusercontent.com/hoafd/dns_adguard/main/dns_setup.sh](https://raw.githubusercontent.com/hoafd/dns_adguard/main/dns_setup.sh) | sudo -E bash
```

---

## ⚙️ Thiết lập sau cài đặt

1. **Cloudflare Zero Trust**: Trỏ **Public Hostname** về `http://localhost:3000`.
2. **AdGuard Home**:
    * Truy cập giao diện web qua Tunnel.
    * Thiết lập Upstream DNS: `127.0.0.1:5335`.
    * Cấu hình SSL bằng chứng chỉ được cấp tại `/etc/letsencrypt/live/`.

---

## ⚖️ License
MIT License. Copyright (c) 2026 hoafd.
