#!/bin/bash
# REPO: https://github.com/hoafd/dns_adguard
# CẬP NHẬT: Mở cổng 3000 để thiết lập trước & Hướng dẫn chi tiết

if [ "$(id -u)" -ne 0 ]; then echo "Vui lòng dùng: sudo -E bash ./dns_setup.sh"; exit 1; fi
BASE_DIR="/opt/server-central/dns"
set -e

echo -e "\e[32m>>> BẮT ĐẦU CÀI ĐẶT HỆ THỐNG DNS MASTER...\e[0m"

# 1. DỌN DẸP CONTAINER CŨ
docker rm -f unbound adguard watchtower 2>/dev/null || true

# 2. CẤU HÌNH RAM (Gợi ý tối đa 512MB để ổn định)
FREE_RAM=$(free -m | awk '/^Mem:/{print $7}')
[ "$FREE_RAM" -gt 2000 ] && SUGGESTED_RAM=512 || SUGGESTED_RAM=256

echo -e "\e[33m>>> RAM rảnh hiện tại: $FREE_RAM MB.\e[0m"
echo -e "\e[36m[HƯỚNG DẪN]: Nhấn ENTER để dùng mức mặc định ($SUGGESTED_RAM MB) hoặc tự nhập số mới.\e[0m"
printf "Cấp RAM cho Unbound (MB): "
read INPUT_RAM < /dev/tty
USER_RAM=${INPUT_RAM:-$SUGGESTED_RAM}
USER_RAM=$(echo "$USER_RAM" | tr -dc '0-9')

# 3. CẤU HÌNH CLOUDFLARE TUNNEL
if systemctl is-active --quiet cloudflared; then
    echo -e "\e[32m[✓] Cloudflare Tunnel đã có sẵn.\e[0m"
    echo -e "\e[36m[HƯỚNG DẪN]: Nhấn ENTER để GIỮ NGUYÊN hoặc dán Token mới để thay đổi.\e[0m"
    printf "Tunnel Token (để trống nếu không đổi): "
    read CF_TOKEN < /dev/tty
else
    echo -e "\e[31m[!] Chưa có Cloudflare Tunnel.\e[0m"
    echo -e "\e[36m[BẮT BUỘC]: Vui lòng dán Tunnel Token của bạn vào đây.\e[0m"
    printf "Token: "
    read CF_TOKEN < /dev/tty
fi
if [ ${#CF_TOKEN} -gt 50 ]; then
    cloudflared service uninstall 2>/dev/null || true
    cloudflared service install "$CF_TOKEN"
fi

# 4. CẤU HÌNH CLOUDFLARE API (TOKEN CHỨNG CHỈ SSL)
echo -e "\e[34m----------------------------------------------------------\e[0m"
echo -e "\e[33m>>> CẤU HÌNH CHỨNG CHỈ SSL (CERTBOT)\e[0m"
echo -e "\e[36m[HƯỚNG DẪN]: Nhấn ENTER để BỎ QUA nếu đã có SSL hoặc cài sau.\e[0m"
printf "Nhập Cloudflare API Token: "
read CF_SSL_TOKEN < /dev/tty

if [ ${#CF_SSL_TOKEN} -gt 10 ]; then
    printf "Nhập Tên miền (VD: dns.hoafd.id.vn): "
    read DOMAIN_NAME < /dev/tty
    printf "Nhập Email quản lý: "
    read EMAIL < /dev/tty
    
    apt update && apt install -y certbot python3-certbot-dns-cloudflare -qq
    mkdir -p ~/.secrets && echo "dns_cloudflare_api_token = $CF_SSL_TOKEN" > ~/.secrets/cloudflare.ini
    chmod 600 ~/.secrets/cloudflare.ini
    certbot certonly --dns-cloudflare --dns-cloudflare-credentials ~/.secrets/cloudflare.ini \
      -d "$DOMAIN_NAME" --non-interactive --agree-tos -m "$EMAIL"
fi

# 5. GIẢI PHÓNG CỔNG 53 & THIẾT LẬP FIREWALL
if lsof -i :53 > /dev/null 2>&1; then
    systemctl stop systemd-resolved || true
    systemctl disable systemd-resolved || true
    echo "nameserver 1.1.1.1" > /etc/resolv.conf
fi

# MỞ CỔNG 3000 ĐỂ THIẾT LẬP TRƯỚC
ufw allow 22/tcp || true
ufw allow 53 || true
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
    volumes: ["./adguard/work:/opt/adguardhome/work","./adguard/conf:/opt/adguardhome/conf"]
    depends_on: [unbound]
EOF

cd "$BASE_DIR" && docker compose up -d --force-recreate

# 7. HƯỚNG DẪN SAU CÀI ĐẶT
SERVER_IP=$(hostname -I | awk '{print $1}')
echo -e "\n\e[32m======================================================================"
echo -e "   CÀI ĐẶT DNS ADGUARD HOÀN TẤT!"
echo -e "======================================================================\e[0m"
echo -e "\e[33mBƯỚC 1: THIẾT LẬP ADGUARD (SETUP WIZARD)\e[0m"
echo -e "   - Truy cập ngay: http://$SERVER_IP:3000"
echo -e "   - Cấu hình giao diện quản trị (Admin Web Interface) tại cổng 3000."
echo -e "   - \e[31mLưu ý:\e[0m Sau khi thiết lập xong, bạn có thể đóng cổng 3000 nếu dùng Tunnel."
echo -e ""
echo -e "\e[33mBƯỚC 2: CẤU HÌNH CLOUDFLARE ZERO TRUST\e[0m"
echo -e "   - Trỏ Public Hostname (dns.hoafd.id.vn) về: http://localhost:3000"
echo -e ""
echo -e "\e[33mBƯỚC 3: KẾT NỐI UNBOUND\e[0m"
echo -e "   - Trong AdGuard Web UI, mục Upstream DNS, điền: 127.0.0.1:5335"
echo -e "\e[32m======================================================================\n\e[0m"
