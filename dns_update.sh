#!/bin/bash
# REPO: https://github.com/hoafd/dns_adguard
# MÔ TẢ: Cập nhật phiên bản AdGuard Home và Unbound mới nhất

if [ "$(id -u)" -ne 0 ]; then echo "Vui lòng dùng: sudo bash ./dns_update.sh"; exit 1; fi
BASE_DIR="/opt/server-central/dns"

echo -e "\e[32m>>> ĐANG KIỂM TRA CẬP NHẬT DNS MASTER...\e[0m"

if [ -d "$BASE_DIR" ]; then
    cd "$BASE_DIR"
    echo "[1/3] Đang tải ảnh Docker mới nhất (AdGuard & Unbound)..."
    docker compose pull
    
    echo "[2/3] Đang khởi động lại hệ thống với phiên bản mới..."
    docker compose up -d
    
    echo "[3/3] Đang dọn dẹp các bản cũ..."
    docker image prune -f
    
    echo -e "\e[32m✅ Cập nhật hoàn tất!\e[0m"
else
    echo -e "\e[31m[!] Lỗi: Không tìm thấy thư mục cài đặt tại $BASE_DIR\e[0m"
    echo "Vui lòng chạy dns_setup.sh trước."
fi
