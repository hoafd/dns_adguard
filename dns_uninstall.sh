#!/bin/bash
# REPO: https://github.com/hoafd/dns_adguard
# MÔ TẢ: Gỡ cài đặt sạch sẽ hệ thống DNS Master, khôi phục systemd-resolved.

if [ "$(id -u)" -ne 0 ]; then 
    echo -e "\e[31m[!] Vui lòng dùng: sudo bash ./dns_uninstall.sh\e[0m"
    exit 1
fi

BASE_DIR="/opt/server-central/dns"

echo -e "\e[33m>>> ĐANG TIẾN HÀNH GỠ CÀI ĐẶT DNS MASTER...\e[0m"

# --- PHẦN 1: DỪNG VÀ XÓA DOCKER ---
if [ -d "$BASE_DIR" ]; then
    echo "[1/6] Đang dừng và xóa Docker containers (AdGuard & Unbound)..."
    cd "$BASE_DIR"
    
    # Lấy cổng AdGuard từ docker-compose hoặc file cấu hình để xóa UFW sau này
    # Mặc định tìm trong lệnh ufw status nếu không thấy file
    ADG_PORT=$(docker ps --format "{{.Ports}}" --filter "name=adguard" | grep -oP '0.0.0.0:\K\d+' | head -n 1)
    
    docker compose down --rmi all --volumes --remove-orphans 2>/dev/null
    echo -e "\e[32m[OK] Đã dọn dẹp Docker.\e[0m"
else
    echo -e "\e[31m[!] Không tìm thấy thư mục cài đặt, bỏ qua bước Docker.\e[0m"
fi

# --- PHẦN 2: KHÔI PHỤC CỔNG 53 (SYSTEMD-RESOLVED) ---
echo "[2/6] Đang khôi phục systemd-resolved (DNS mặc định)..."
systemctl enable systemd-resolved || true
systemctl start systemd-resolved || true
# Trả lại file resolv.conf về mặc định của systemd
rm -f /etc/resolv.conf
ln -s /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf || echo "nameserver 8.8.8.8" > /etc/resolv.conf
echo -e "\e[32m[OK] Đã khôi phục cài đặt DNS hệ thống.\e[0m"

# --- PHẦN 3: DỌN DẸP TƯỜNG LỬA (UFW) ---
echo "[3/6] Đang xóa các quy tắc tường lửa..."
ufw delete allow 53/tcp > /dev/null 2>&1
ufw delete allow 53/udp > /dev/null 2>&1
if [ ! -z "$ADG_PORT" ]; then
    ufw delete allow "$ADG_PORT/tcp" > /dev/null 2>&1
fi
# Xóa mặc định cổng 3000 nếu không tìm thấy port
ufw delete allow 3000/tcp > /dev/null 2>&1
echo -e "\e[32m[OK] Đã cập nhật UFW.\e[0m"

# --- PHẦN 4: XÓA LỊCH DỌN DẸP (CRONTAB) ---
echo "[4/6] Đang xóa Cronjob bảo trì..."
(crontab -l 2>/dev/null | grep -v "docker system prune" ; echo "") | crontab -
echo -e "\e[32m[OK] Đã dọn dẹp Crontab.\e[0m"

# --- PHẦN 5: GỠ CLOUDFLARE TUNNEL (NẾU CÓ) ---
if command -v cloudflared &> /dev/null; then
    echo "[5/6] Đang gỡ bỏ Cloudflare Tunnel..."
    cloudflared service uninstall > /dev/null 2>&1
fi

# --- PHẦN 6: XÓA DỮ LIỆU ---
echo "[6/6] Đang xóa thư mục dữ liệu tại $BASE_DIR..."
rm -rf "$BASE_DIR"
echo -e "\e[32m[OK] Đã xóa toàn bộ thư mục.\e[0m"

echo -e "\n\e[32m======================================================================"
echo -e "    ✨ ĐÃ GỠ CÀI ĐẶT DNS MASTER THÀNH CÔNG!"
echo -e "    Hệ thống đã quay về cấu hình DNS mặc định của Ubuntu."
echo -e "======================================================================\e[0m\n"
