#!/bin/bash
# REPO: https://github.com/hoafd/dns_adguard
# CẬP NHẬT: Tự động cài Docker + Giữ nguyên hướng dẫn & SSL Renew Hook

if [ "$(id -u)" -ne 0 ]; then echo "Vui lòng dùng: sudo -E bash ./dns_setup.sh"; exit 1; fi
BASE_DIR="/opt/server-central/dns"
set -e

echo -e "\e[32m>>> ĐANG KHỞI TẠO HỆ THỐNG DNS MASTER...\e[0m"

# --- PHẦN MỚI: TỰ ĐỘNG CÀI ĐẶT DOCKER ---
if ! [ -x "$(command -v docker)" ]; then
    echo -e "\e[33m[!] Docker chưa có. Đang cài đặt tự động...\e[0m"
    curl -fsSL https://get.docker.com | sh
    systemctl enable --now docker
fi
if ! docker compose version > /dev/null 2>&1; then
    echo -e "\e[33m[!] Đang cài đặt Docker Compose Plugin...\e[0m"
    apt-get update && apt-get install -y docker-compose-v2 -qq
fi
# ---------------------------------------

# 1. DỌN DẸP
docker rm -f unbound adguard 2>/dev/null || true

# 2. CẤU HÌNH RAM (768MB)
echo -e "\e[33m>>> RAM rảnh hiện tại: $(free -m | awk '/^Mem:/{print $7}') MB.\e[0m"
printf "Cấp RAM cho Unbound (MB, Enter để lấy 768): "
read INPUT_RAM < /dev/tty
USER_RAM=${INPUT_RAM:-768}
USER_RAM=$(echo "$USER_RAM" | tr -dc '0-9')

# 3. CẤU HÌNH CLOUDFLARE TUNNEL
if systemctl is-active --quiet cloudflared; then
    printf "Tunnel Token (Nhấn Enter để giữ nguyên): "
    read CF_TOKEN < /dev/tty
else
    printf "Dán Tunnel Token [BẮT BUỘC]: "
    read CF_TOKEN < /dev/tty
fi
[ ${#CF_TOKEN} -gt 50 ] && (cloudflared service uninstall || true; cloudflared service install "$CF_TOKEN")

# 4. CẤU HÌNH SSL VỚI RENEW HOOK
printf "Nhập Cloudflare API Token để cấp SSL (Enter nếu đã có SSL): "
read CF_SSL_TOKEN < /dev/tty
HAS_SSL=false
if [ ${#CF_SSL_TOKEN} -gt 10 ]; then
    printf "Nhập Tên miền (VD: dns.hoafd.id.vn): "
    read DOMAIN_NAME < /dev/tty
    printf "Nhập Email: "
    read EMAIL < /dev/tty
    apt update && apt install -y certbot python3-certbot-dns-cloudflare -qq
    mkdir -p ~/.secrets && echo "dns_cloudflare_api_token = $CF_SSL_TOKEN" > ~/.secrets/cloudflare.ini
    chmod 600 ~/.secrets/cloudflare.ini
    certbot certonly --dns-cloudflare --dns-cloudflare-credentials ~/.secrets/cloudflare.ini \
      -d "$DOMAIN_NAME" --non-interactive --agree-tos -m "$EMAIL" --deploy-hook "docker restart adguard"
    HAS_SSL=true
fi

# 5. FIREWALL & GIẢI PHÓNG CỔNG 53
ufw allow 22/tcp && ufw allow 53 && ufw allow 3000/tcp && ufw allow 80/tcp && ufw allow 443/tcp
echo "y" | ufw enable
[ -f /etc/resolv.conf ] && (systemctl stop systemd-resolved || true; systemctl disable systemd-resolved || true; echo "nameserver 1.1.1.1" > /etc/resolv.conf)

# 6. KHỞI CHẠY DOCKER
mkdir -p "$BASE_DIR/unbound" "$BASE_DIR/adguard/conf" "$BASE_DIR/adguard/work"
MSG_CACHE=$((USER_RAM / 3))
RRSET_CACHE=$((USER_RAM * 2 / 3))

cat <<EOF > "$BASE_DIR/unbound/unbound.conf"
server:
    interface: 0.0.0.0
    port: 5335
    access-control: 0.0.0.0/0 allow
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
    volumes: ["./adguard/work:/opt/adguardhome/work","./adguard/conf:/opt/adguardhome/conf","/etc/letsencrypt:/etc/letsencrypt:ro"]
EOF

cd "$BASE_DIR" && docker compose up -d --force-recreate

# 7. HƯỚNG DẪN SAU CÀI ĐẶT (ĐÃ KHÔI PHỤC)
SERVER_IP=$(hostname -I | awk '{print $1}')
echo -e "\n\e[32m======================================================================"
echo -e "   🎉 CẬP NHẬT DNS MASTER THÀNH CÔNG!"
echo -e "======================================================================\e[0m"
echo -e "👉 Truy cập Web UI thiết lập: \e[36mhttp://$SERVER_IP:3000\e[0m"
echo -e "✅ Đã thiết lập Auto-Restart AdGuard mỗi khi SSL gia hạn."
if [ "$HAS_SSL" = true ]; then
echo -e "✅ Chứng chỉ cho: \e[32m$DOMAIN_NAME\e[0m"
echo -e "   - Cert path: /etc/letsencrypt/live/$DOMAIN_NAME/fullchain.pem"
echo -e "   - Key path: /etc/letsencrypt/live/$DOMAIN_NAME/privkey.pem"
fi
echo -e "\e[33mBƯỚC TIẾP THEO:\e[0m"
echo -e "1. Vào AdGuard -> DNS Settings -> Upstream: 127.0.0.1:5335"
echo -e "2. Thêm Blocklist từ Repo 'my-dns-blocklist' của bạn."
echo -e "\e[32m======================================================================\n\e[0m"
