#!/bin/bash
# REPO: https://github.com/hoafd/dns_adguard
# MÔ TẢ: Kiểm tra sức khỏe hệ thống DNS AdGuard & Unbound

echo -e "\e[34m"
echo "======================================================"
echo "    KẾT QUẢ KIỂM TRA SỨC KHỎE HỆ THỐNG DNS"
echo "======================================================"
echo -e "\e[0m"

# 1. KIỂM TRA DOCKER CONTAINERS
echo -n "[1/4] Kiểm tra Container: "
ADGUARD_STATUS=$(docker inspect -f '{{.State.Status}}' adguard 2>/dev/null)
UNBOUND_STATUS=$(docker inspect -f '{{.State.Status}}' unbound 2>/dev/null)

if [ "$ADGUARD_STATUS" == "running" ] && [ "$UNBOUND_STATUS" == "running" ]; then
    echo -e "\e[32m[OK] AdGuard & Unbound đang chạy.\e[0m"
else
    echo -e "\e[31m[LỖI] Kiểm tra lại Docker: AdGuard ($ADGUARD_STATUS), Unbound ($UNBOUND_STATUS)\e[0m"
fi

# 2. KIỂM TRA PORT
echo -n "[2/4] Kiểm tra Cổng mạng: "
PORT_53=$(ss -tunlp | grep -w 53)
PORT_5335=$(ss -tunlp | grep -w 5335)

if [ ! -z "$PORT_53" ] && [ ! -z "$PORT_5335" ]; then
    echo -e "\e[32m[OK] Cổng 53 và 5335 đã mở.\e[0m"
else
    echo -e "\e[31m[LỖI] Cổng DNS chưa sẵn sàng.\e[0m"
fi

# 3. KIỂM TRA PHÂN GIẢI DNS (Dùng Dig hoặc Nslookup)
echo -n "[3/4] Kiểm tra Truy vấn sạch (google.com): "
CLEAN_TEST=$(dig @127.0.0.1 google.com +short +time=2 +tries=1)

if [ ! -z "$CLEAN_TEST" ]; then
    echo -e "\e[32m[OK] Đã phân giải: $CLEAN_TEST\e[0m"
else
    echo -e "\e[31m[LỖI] Không thể kết nối tới DNS để truy vấn.\e[0m"
fi

# 4. KIỂM TRA CHẶN QUẢNG CÁO
echo -n "[4/4] Kiểm tra Chặn (doubleclick.net): "
BLOCK_TEST=$(dig @127.0.0.1 doubleclick.net +short +time=2 +tries=1)

if [ "$BLOCK_TEST" == "0.0.0.0" ] || [ -z "$BLOCK_TEST" ]; then
    echo -e "\e[32m[OK] Đã chặn thành công (Kết quả: $BLOCK_TEST)\e[0m"
else
    echo -e "\e[33m[CẢNH BÁO] Chưa chặn được quảng cáo (Trả về: $BLOCK_TEST)\e[0m"
fi

echo -e "\e[34m"
echo "======================================================"
echo "          KIỂM TRA HOÀN TẤT - $(date)"
echo "======================================================"
echo -e "\e[0m"
