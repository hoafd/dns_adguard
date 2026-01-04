#!/bin/bash
# REPO: https://github.com/hoafd/dns_adguard
# CẬP NHẬT: Mở cổng 3000, 80, 443 & Hướng dẫn SSL chi tiết

if [ "$(id -u)" -ne 0 ]; then echo "Vui lòng dùng: sudo -E bash ./dns_setup.sh"; exit 1; fi
BASE_DIR="/opt/server-central/dns"
set -e

echo -e "\e[32m>>> BẮT ĐẦU CÀI ĐẶT DNS MASTER...\e[0m"

# 1. DỌN DẸP CONTAINER CŨ
docker rm -f unbound adguard 2>/dev/null || true

# 2. CẤU HÌNH RAM
FREE_RAM=$(free -m | awk '/^Mem:/{print $7}')
[ "$FREE_RAM" -gt 2000 ] && SUGGESTED_RAM=512 || SUGGESTED_RAM=256
printf "Cấp RAM cho Unbound (MB, Enter để lấy $SUGGESTED_RAM): "
read INPUT_RAM < /dev/tty
USER_RAM=${INPUT_RAM:-$SUGGESTED_RAM}
USER_RAM=$(echo "$USER_RAM" | tr -dc '0-9')

# 3. CẤU HÌNH CLOUDFLARE TUNNEL
if systemctl is-active --quiet cloudflared; then
    printf "Tunnel Token (Nhấn Enter để giữ nguyên): "
    read CF_TOKEN < /dev/tty
else
    printf "Dán Tunnel Token [BẮT BUỘC]: "
    read CF_TOKEN < /dev/tty
fi
if [ ${#CF_TOKEN} -gt 50 ]; then
    cloudflared service uninstall 2>/dev/null || true
    cloudflared service install "$CF_TOKEN"
fi

# 4. CẤU HÌNH SSL (CERTBOT DNS-01)
echo -e "\e[34m----------------------------------------------------------\e[0m"
echo -e "\e[33m>>> CÀI ĐẶT CHỨNG CHỈ SSL CHUYÊN NGHIỆP\e[0m"
printf "Nhập Cloudflare API Token (Nhấn Enter để bỏ qua): "
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
      -d "$DOMAIN_NAME" --non-interactive --agree-tos -m "$EMAIL"
    HAS_SSL=true
fi

# 5. FIREWALL & CỔNG
ufw allow 22/tcp || true
ufw allow 53 || true
ufw allow 80/tcp || true
ufw allow 443/tcp || true
ufw allow 3000/tcp || true
ufw default deny incoming || true
echo "y" | ufw enable || true

# 6. KHỞI CHẠY DOCKER
mkdir -p "$BASE_DIR/unbound" "$BASE_DIR/adguard/conf" "$BASE_DIR/adguard/work"
MSG_CACHE=$((USER_RAM / 3))
RRSET_CACHE=$((USER_RAM * 2 / 3))

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
    volumes: ["./adguard/work:/opt/adguardhome/work","./adguard/conf:/opt/adguardhome/conf","/etc/letsencrypt:/etc/letsencrypt:ro"]
    depends_on: [unbound]
EOF

cd "$BASE_DIR" && docker compose up -d --force-recreate

# 7. HƯỚNG DẪN SAU CÀI ĐẶT CỰC CHI TIẾT
SERVER_IP=$(hostname -I | awk '{print $1}')
echo -e "\n\e[32m======================================================================"
echo -e "   🎉 CÀI ĐẶT DNS ADGUARD HOÀN TẤT!"
echo -e "======================================================================\e[0m"
echo -e "\e[33mBƯỚC 1: THIẾT LẬP ADGUARD (SETUP WIZARD)\e[0m"
echo -e "   👉 Truy cập: \e[36mhttp://$SERVER_IP:3000\e[0m"
echo -e ""
if [ "$HAS_SSL" = true ]; then
echo -e "\e[33mBƯỚC 2: CÀI ĐẶT CHỨNG CHỈ SSL VÀO ADGUARD\e[0m"
echo -e "   - Trong Web AdGuard: Vào 'Settings' -> 'Encryption settings'."
echo -e "   - Bật 'Enable Encryption'."
echo -e "   - Server name: \e[32m$DOMAIN_NAME\e[0m"
echo -e "   - Certificate path: \e[32m/etc/letsencrypt/live/$DOMAIN_NAME/fullchain.pem\e[0m"
echo -e "   - Private key path: \e[32m/etc/letsencrypt/live/$DOMAIN_NAME/privkey.pem\e[0m"
echo -e ""
fi
echo -e "\e[33mBƯỚC 3: KẾT NỐI UNBOUND\e[0m"
echo -e "   - Settings -> DNS Settings -> Upstream DNS điền: \e[32m127.0.0.1:5335\e[0m"
echo -e "\e[32m======================================================================\n\e[0m"
