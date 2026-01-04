#!/bin/bash
# REPO: https://github.com/hoafd/dns_adguard
# CẬP NHẬT: Tự động Restart AdGuard khi SSL gia hạn (Renew Hook)

if [ "$(id -u)" -ne 0 ]; then echo "Vui lòng dùng: sudo -E bash ./dns_setup.sh"; exit 1; fi
BASE_DIR="/opt/server-central/dns"
set -e

echo -e "\e[32m>>> ĐANG KHỞI TẠO HỆ THỐNG DNS MASTER (HỖ TRỢ AUTO-RENEW SSL)...\e[0m"

# 1. DỌN DẸP CONTAINER CŨ
docker rm -f unbound adguard 2>/dev/null || true

# 2. CẤU HÌNH RAM (Tối ưu cho Unbound theo yêu cầu của bạn)
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
[ ${#CF_TOKEN} -gt 50 ] && (cloudflared service uninstall || true; cloudflared service install "$CF_TOKEN")

# 4. CẤU HÌNH SSL VỚI RENEW HOOK
echo -e "\e[34m----------------------------------------------------------\e[0m"
echo -e "\e[33m>>> CÀI ĐẶT CHỨNG CHỈ SSL (CERTBOT DNS-01)\e[0m"
printf "Nhập Cloudflare API Token (Nhấn Enter nếu đã có SSL): "
read CF_SSL_TOKEN < /dev/tty

HAS_SSL=false
if [ ${#CF_SSL_TOKEN} -gt 10 ]; then
    printf "Nhập Tên miền (VD: dns.hoafd.id.vn): "
    read DOMAIN_NAME < /dev/tty
    printf "Nhập Email quản lý: "
    read EMAIL < /dev/tty
    
    apt update && apt install -y certbot python3-certbot-dns-cloudflare -qq
    mkdir -p ~/.secrets && echo "dns_cloudflare_api_token = $CF_SSL_TOKEN" > ~/.secrets/cloudflare.ini
    chmod 600 ~/.secrets/cloudflare.ini
    
    # Lệnh Certbot với --deploy-hook để tự động restart AdGuard khi có chứng chỉ mới
    certbot certonly --dns-cloudflare \
      --dns-cloudflare-credentials ~/.secrets/cloudflare.ini \
      -d "$DOMAIN_NAME" \
      --non-interactive --agree-tos -m "$EMAIL" \
      --deploy-hook "docker restart adguard"
    HAS_SSL=true
fi

# 5. FIREWALL & GIẢI PHÓNG CỔNG 53
ufw allow 22/tcp && ufw allow 53 && ufw allow 80/tcp && ufw allow 443/tcp && ufw allow 3000/tcp
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
EOF

cd "$BASE_DIR" && docker compose up -d --force-recreate

# 7. HƯỚNG DẪN SAU CÀI ĐẶT
SERVER_IP=$(hostname -I | awk '{print $1}')
echo -e "\n\e[32m======================================================================"
echo -e "   🎉 CẬP NHẬT DNS MASTER THÀNH CÔNG!"
echo -e "======================================================================\e[0m"
echo -e "👉 Truy cập Web UI: \e[36mhttp://$SERVER_IP:3000\e[0m"
echo -e "✅ Đã thiết lập Auto-Restart AdGuard mỗi khi SSL gia hạn thành công."
if [ "$HAS_SSL" = true ]; then
echo -e "✅ Chứng chỉ cho: \e[32m$DOMAIN_NAME\e[0m"
echo -e "   - Cert path: /etc/letsencrypt/live/$DOMAIN_NAME/fullchain.pem"
echo -e "   - Key path: /etc/letsencrypt/live/$DOMAIN_NAME/privkey.pem"
fi
echo -e "\e[32m======================================================================\n\e[0m"
