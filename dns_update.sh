#!/bin/bash
# REPO: https://github.com/hoafd/dns_adguard
# MÔ TẢ: Cập nhật DNS an toàn (Dừng -> Pull -> Chạy)

if [ "$(id -u)" -ne 0 ]; then echo "Vui lòng dùng: sudo bash ./dns_update.sh"; exit 1; fi
BASE_DIR="/opt/server-central/dns"

echo -e "\e[32m>>> BẮT ĐẦU CẬP NHẬT DNS MASTER (SAFE MODE)...\e[0m"

if [ -d "$BASE_DIR" ]; then
    cd "$BASE_DIR"
    
    echo "[1/4] Đang dừng hệ thống để tránh xung đột..."
    docker compose down
    
    echo "[2/4] Đang tải bản AdGuard & Unbound mới nhất..."
    docker compose pull
    
    echo "[3/4] Đang tái khởi động hệ thống..."
    docker compose up -d
    
    echo "[4/4] Dọn dẹp tài nguyên cũ..."
    docker image prune -f
    
    echo -e "\e[32m✅ Cập nhật hoàn tất và an toàn!\e[0m"
else
    echo -e "\e[31m[!] Lỗi: Không tìm thấy thư mục tại $BASE_DIR\e[0m"
fi
