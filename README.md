# 🛡️ DNS AdGuard Master

Hệ thống DNS chặn quảng cáo bảo mật cao tích hợp **AdGuard Home** và **Unbound**, được tối ưu hóa đặc biệt cho hiệu suất và bảo mật trên **Ubuntu 24.04**. Toàn bộ dịch vụ vận hành nội bộ và truy cập an toàn qua **Cloudflare Zero Trust**.



---

## 📋 Điều kiện hệ thống chạy

Để hệ thống hoạt động ổn định và tối ưu, máy chủ cần đáp ứng:

* **Hệ điều hành**: Ubuntu 24.04 LTS (Khuyên dùng) hoặc Debian 11/12.
* **Kiến trúc CPU**: x86_64 (amd64).
* **Bộ nhớ (RAM)**: 
    * **Tối thiểu**: 512MB RAM trống.
    * **Tối ưu**: 1GB RAM trở lên để khai thác tối đa khả năng đệ quy của Unbound.
* **Mạng & Cổng (Ports)**:
    * Cổng **53 (UDP/TCP)**: Phải sẵn dụng (Script sẽ tự động giải phóng khỏi `systemd-resolved`).
    * Cổng **22 (SSH)**: Mở để quản trị từ xa.
    * Cổng **3000**: Giữ nội bộ (Chỉ truy cập qua Cloudflare Tunnel).
* **Phần mềm**: Yêu cầu quyền `sudo` để thực thi các thiết lập hệ thống và Docker.

---

## 🛠️ Hướng dẫn cài đặt nhanh

Thực hiện lệnh sau để cài đặt tự động:

```bash
curl -sSL [https://raw.githubusercontent.com/hoafd/dns_adguard/main/dns_setup.sh](https://raw.githubusercontent.com/hoafd/dns_adguard/main/dns_setup.sh) | sudo -E bash
```

---

## ⚙️ Thiết lập sau cài đặt

1. **Cloudflare Zero Trust**: Trỏ **Public Hostname** (VD: `dns.hoafd.id.vn`) về địa chỉ: `http://localhost:3000`.
2. **DNS Upstream**: Trong giao diện AdGuard Home, vào *Cài đặt DNS*, nhập Upstream duy nhất là: `127.0.0.1:5335`.
3. **Bảo mật**: Hệ thống đã tự động kích hoạt **UFW** và chỉ cho phép cổng 22, 53. Mọi truy cập vào trang quản trị phải đi qua Tunnel.

---

## ⚖️ Giấy phép (License)

Dự án này được cấp phép theo các điều khoản của **MIT License**. Xem chi tiết tại file [LICENSE](LICENSE).

---
**Phát triển bởi [hoafd](https://github.com/hoafd)**
