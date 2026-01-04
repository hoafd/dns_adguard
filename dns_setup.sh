#!/bin/bash
# REPO: https://github.com/hoafd/dns_adguard
# FIX: Tối ưu mức RAM đề xuất & Hướng dẫn nhập liệu rõ ràng

if [ "$(id -u)" -ne 0 ]; then echo "Vui lòng dùng: sudo -E bash ./dns_setup.sh"; exit 1; fi
BASE_DIR="/opt/server-central/dns"
set -e

echo -e "\e[32m>>> ĐANG KHỞI TẠO HỆ THỐNG DNS MASTER...\e[0m"

# 1. DỌN DẸP CONTAINER CŨ
docker rm -f unbound adguard 2>/dev/null || true

# 2. KIỂM TRA RAM VÀ TÍNH TOÁN MỨC ĐỀ XUẤT
FREE_RAM=$(free -m | awk '/^Mem:/{print $7}')
# Nếu RAM rảnh > 1024MB thì đề xuất 512MB, nếu ít hơn thì lấy 256MB
if [ "$FREE_RAM" -gt 1024 ]; then SUGGESTED_RAM=512; else SUGGESTED_RAM=256; fi

echo -e "\e[33m>>> RAM rảnh hiện tại: $FREE_RAM MB.\e[0m"
echo -e "\e[36m[HƯỚNG DẪN]: Nhấn ENTER để dùng mức mặc định ($SUGGESTED_RAM MB) hoặc tự nhập số mới.\e[0m"
printf "Cấp RAM cho Unbound Cache (MB): "
read INPUT_RAM < /dev/tty
USER_RAM=${INPUT_RAM:-$SUGGESTED_RAM}

USER_RAM=$(echo "$USER_RAM" | tr -dc '0-9')
MSG_CACHE=$((USER_RAM / 3))
RRSET_CACHE=$((USER_RAM * 2 / 3))

# 3. KIỂM TRA CLOUDFLARE TUNNEL
if systemctl is-active --quiet cloudflared; then
    echo -e "\e[32m[✓] Cloudflare Tunnel đã có sẵn.\e[0m"
    echo -e "\e[36m[HƯỚNG DẪN]: Nhấn ENTER để GIỮ NGUYÊN hoặc nhập Token mới để thay đổi.\e[0m"
    printf "Token (để trống nếu không đổi): "
    read CF_TOKEN < /dev/tty
else
    echo -e "\e[31m[!] Chưa tìm thấy Cloudflare Tunnel trên máy.\e[0m"
    echo -e "\e[36m[BẮT BUỘC]: Vui lòng dán Token của bạn vào đây để cài đặt.\e[0m"
    printf "Token: "
    read CF_TOKEN < /dev/tty
fi

if [ ${#CF_TOKEN} -gt 50 ]; then
    cloudflared service uninstall 2>/dev/null || true
    cloudflared service install "$CF_TOKEN"
fi

# 4. GIẢI PHÓNG CỔNG 53 & CẤU HÌNH DOCKER (Giữ nguyên phần cấu hình cũ)
if lsof -i :53 > /dev/null 2>&1; then
    systemctl stop systemd-resolved || true
    systemctl disable systemd-resolved || true
    echo "nameserver 1.1.1.1" > /etc/resolv.conf
fi

mkdir -p "$BASE_DIR/unbound" "$BASE_DIR/adguard/conf" "$BASE_DIR/adguard/work"

cat <<EOF > "$BASE_DIR/unbound/unbound.conf"
server:
    interface: 0.0.0.0
    port: 5335
    access-control: 0.0.0.0/0 allow
    num-threads: $(nproc)
    msg-cache-size: ${MSG_CACHE}m
    rrset-cache-size: ${RRSET_CACHE}m
EOF

cat <<EOF > "$BASE_DIR/docker-compose.yml"
services:
  unbound:
    image: mvance/unbound:latest
    container_name: unbound
    restart: unless-stopped
    network_mode: host
    volumes: ["./unbound/unbound.conf:/opt/unbound/etc/unbound/unbound.conf:ro"]
  adguard:
    image: adguard/adguardhome:latest
    container_name: adguard
    restart: unless-stopped
    network_mode: host
    volumes: ["./adguard/work:/opt/adguardhome/work","./adguard/conf:/opt/adguardhome/conf"]
    depends_on: [unbound]
EOF

cd "$BASE_DIR" && docker compose up -d --force-recreate
echo -e "\e[32m[✓] CÀI ĐẶT DNS THÀNH CÔNG VỚI $USER_RAM MB RAM CACHE!\e[0m"
