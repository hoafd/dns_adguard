#!/bin/bash
# ==============================================================================
# SCRIPT: CÀI ĐẶT DNS MASTER (ADGUARD + UNBOUND) - BẢO MẬT & TỐI ƯU
# REPO: https://github.com/hoafd/dns_adguard
# ==============================================================================

if [ "$(id -u)" -ne 0 ]; then echo "Vui lòng dùng: sudo -E bash ./dns_setup.sh"; exit 1; fi
REAL_USER=${SUDO_USER:-$USER}
BASE_DIR="/opt/server-central/dns"
set -e

# 1. KIỂM TRA RAM TRỐNG
FREE_RAM=$(free -m | awk '/^Mem:/{print $7}')
SUGGESTED_RAM=$((FREE_RAM / 2))
echo -e "\e[33m>>> HỆ THỐNG: Còn trống $FREE_RAM MB RAM.\e[0m"
read -p "Cấp RAM cho DNS (MB, nhấn Enter để lấy $SUGGESTED_RAM): " USER_RAM
USER_RAM=${USER_RAM:-$SUGGESTED_RAM}
MSG_CACHE=$((USER_RAM / 3))
RRSET_CACHE=$((USER_RAM * 2 / 3))

# 2. GIẢI PHÓNG CỔNG 53 & KIỂM TRA TUNNEL
if lsof -i :53 > /dev/null 2>&1; then
    systemctl stop systemd-resolved || true
    systemctl disable systemd-resolved || true
    echo "nameserver 1.1.1.1" > /etc/resolv.conf
fi

if systemctl is-active --quiet cloudflared; then
    echo -e "\e[32m[✓] Cloudflare Tunnel đã sẵn sàng.\e[0m"
    read -p "Nhập Token mới (hoặc Enter để bỏ qua): " CF_TOKEN
else
    read -p "Nhập Cloudflare Tunnel Token: " CF_TOKEN
fi
[ -n "$CF_TOKEN" ] && (cloudflared service uninstall || true; cloudflared service install "$CF_TOKEN")

# 3. CÀI ĐẶT DOCKER & CẤU HÌNH
mkdir -p "$BASE_DIR/unbound" "$BASE_DIR/adguard/conf" "$BASE_DIR/adguard/work"

cat <<EOF > "$BASE_DIR/unbound/unbound.conf"
server:
    interface: 0.0.0.0
    port: 5335
    access-control: 0.0.0.0/0 allow
    num-threads: $(nproc)
    msg-cache-size: ${MSG_CACHE}m
    rrset-cache-size: ${RRSET_CACHE}m
    cache-min-ttl: 3600
    prefetch: yes
    serve-expired: yes
    so-rcvbuf: 8m
    so-sndbuf: 8m
EOF

cat <<EOF > "$BASE_DIR/docker-compose.yml"
services:
  unbound:
    image: mvance/unbound:latest
    container_name: unbound
    restart: unless-stopped
    volumes: ["./unbound/unbound.conf:/opt/unbound/etc/unbound/unbound.conf:ro"]
    network_mode: host
  adguard:
    image: adguard/adguardhome:latest
    container_name: adguard
    restart: unless-stopped
    volumes:
      - ./adguard/work:/opt/adguardhome/work
      - ./adguard/conf:/opt/adguardhome/conf
      - /etc/letsencrypt:/etc/letsencrypt:ro
    network_mode: host
    depends_on: [unbound]
EOF

# 4. FIREWALL (CHỈ MỞ CỔNG CẦN THIẾT)
ufw allow 22/tcp
ufw allow 53
ufw default deny incoming
echo "y" | ufw enable

# 5. KHỞI CHẠY & HƯỚNG DẪN
chown -R "$REAL_USER:$REAL_USER" "$BASE_DIR"
cd "$BASE_DIR" && docker compose up -d

echo -e "\n\e[32m======================================================================"
echo -e "   CÀI ĐẶT DNS MASTER HOÀN TẤT!"
echo -e "======================================================================\e[0m"
echo -e "\e[33mBƯỚC TIẾP THEO:\e[0m"
echo -e "1. Cloudflare Zero Trust: Trỏ domain về http://localhost:3000"
echo -e "2. Truy cập AdGuard UI: Thiết lập DNS Upstream là '127.0.0.1:5335'"
echo -e "3. Bảo mật: Cổng 3000 đã bị UFW chặn, chỉ truy cập được qua Tunnel."
echo -e "======================================================================\n"
