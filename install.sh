#!/bin/bash

# Warna teks
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}[+] Selamat datang di installer proxy server by aethereal${NC}"

# Meminta input dari pengguna
echo -e "${GREEN}[+] Silakan masukkan konfigurasi proxy:${NC}"
read -p "Masukkan IP VPS: " IP_VPS
read -p "Masukkan username proxy [default: aethereal]: " PROXY_USER
PROXY_USER=${PROXY_USER:-aethereal}
read -p "Masukkan password proxy [default: aethereal]: " PROXY_PASS
PROXY_PASS=${PROXY_PASS:-aethereal}
read -p "Masukkan port HTTP [default: 8080]: " HTTP_PORT
HTTP_PORT=${HTTP_PORT:-8080}
read -p "Masukkan port SOCKS [default: 1080]: " SOCKS_PORT
SOCKS_PORT=${SOCKS_PORT:-1080}

# Konfirmasi konfigurasi
echo -e "${GREEN}[+] Konfigurasi yang akan digunakan:${NC}"
echo -e "IP VPS: $IP_VPS"
echo -e "Username proxy: $PROXY_USER"
echo -e "Password proxy: $PROXY_PASS"
echo -e "Port HTTP: $HTTP_PORT"
echo -e "Port SOCKS: $SOCKS_PORT"
read -p "Lanjutkan instalasi? [y/n]: " confirm
if [[ $confirm != "y" && $confirm != "Y" ]]; then
    echo -e "${RED}[!] Instalasi dibatalkan.${NC}"
    exit 1
fi

echo -e "${GREEN}[+] Memulai instalasi proxy server...${NC}"

# Tunggu jika ada proses apt yang sedang berjalan
while pgrep apt > /dev/null; do
    echo -e "${RED}[!] Menunggu proses apt lain selesai...${NC}"
    sleep 10
done

# Update dan instalasi paket yang diperlukan
echo -e "${GREEN}[+] Memperbarui sistem dan menginstal paket yang diperlukan...${NC}"
apt-get update
apt-get install -y squid apache2-utils dante-server curl

# Konfigurasi Squid untuk HTTP/HTTPS proxy
echo -e "${GREEN}[+] Mengkonfigurasi Squid untuk HTTP/HTTPS proxy...${NC}"

# Buat file password
touch /etc/squid/passwords
chmod 777 /etc/squid/passwords
htpasswd -b -c /etc/squid/passwords $PROXY_USER $PROXY_PASS

# Backup konfigurasi squid asli
mv /etc/squid/squid.conf /etc/squid/squid.conf.bak

# Buat konfigurasi squid baru
cat > /etc/squid/squid.conf << EOF
auth_param basic program /usr/lib/squid/basic_ncsa_auth /etc/squid/passwords
auth_param basic realm Squid proxy-caching web server
auth_param basic credentialsttl 24 hours
auth_param basic casesensitive off
acl authenticated proxy_auth REQUIRED
http_access allow authenticated
http_access deny all
dns_v4_first on
forwarded_for delete
via off
# Menggunakan DNS Google dan Cloudflare
dns_nameservers 8.8.8.8 1.1.1.1
http_port $HTTP_PORT
EOF

# Restart Squid
systemctl restart squid
systemctl enable squid

# Konfigurasi Dante untuk SOCKS5 proxy
echo -e "${GREEN}[+] Mengkonfigurasi Dante untuk SOCKS5 proxy...${NC}"

# Backup konfigurasi dante asli
mv /etc/danted.conf /etc/danted.conf.bak

# Buat konfigurasi dante baru
cat > /etc/danted.conf << EOF
logoutput: /var/log/danted.log
internal: $IP_VPS port = $SOCKS_PORT
external: $IP_VPS
socksmethod: username
user.privileged: root
user.notprivileged: nobody
user.libwrap: nobody
client pass {
    from: 0.0.0.0/0 to: 0.0.0.0/0
    log: error connect disconnect
}
socks pass {
    from: 0.0.0.0/0 to: 0.0.0.0/0
    log: error connect disconnect
}
EOF

# Tambahkan pengguna untuk autentikasi SOCKS5
echo -e "${GREEN}[+] Menambahkan pengguna untuk autentikasi SOCKS5...${NC}"
useradd -r -s /bin/false $PROXY_USER 2>/dev/null || true
echo "$PROXY_USER:$PROXY_PASS" | chpasswd

# Restart Dante
systemctl restart danted
systemctl enable danted

# Buka port jika iptables ada
echo -e "${GREEN}[+] Membuka port firewall...${NC}"
if command -v iptables &> /dev/null; then
    iptables -A INPUT -p tcp --dport $HTTP_PORT -j ACCEPT
    iptables -A INPUT -p tcp --dport $SOCKS_PORT -j ACCEPT
fi

# Konfigurasi DNS Google dan Cloudflare untuk sistem
echo -e "${GREEN}[+] Mengkonfigurasi DNS Google dan Cloudflare...${NC}"
cat > /etc/resolv.conf << EOF
nameserver 8.8.8.8
nameserver 1.1.1.1
EOF

# Tampilkan informasi proxy
echo -e "${GREEN}[+] Instalasi proxy server selesai!${NC}"
echo -e "${GREEN}=== DETAIL PROXY ====${NC}"
echo -e "HTTP/HTTPS Proxy: ${IP_VPS}:${HTTP_PORT}:${PROXY_USER}:${PROXY_PASS}"
echo -e "SOCKS5 Proxy: ${IP_VPS}:${SOCKS_PORT}:${PROXY_USER}:${PROXY_PASS}"
echo -e "${GREEN}====================${NC}"

# Status layanan
echo -e "Status layanan Squid:"
systemctl status squid --no-pager
echo -e "Status layanan Dante:"
systemctl status danted --no-pager

# Menampilkan hasil akhir dan membuat file proxy.txt
echo -e "${GREEN}[+] PROXY BERHASIL DIBUAT${NC}"
echo -e "${GREEN}[+] Detail proxy Anda:${NC}"
echo -e "===================================="
echo -e "HTTP Proxy: http://${PROXY_USER}:${PROXY_PASS}@${IP_VPS}:${HTTP_PORT}"
echo -e "SOCKS5 Proxy: socks5://${PROXY_USER}:${PROXY_PASS}@${IP_VPS}:${SOCKS_PORT}"
echo -e "===================================="

# Membuat file proxy.txt
echo -e "${GREEN}[+] Membuat file proxy.txt...${NC}"
cat > proxy.txt << EOF
===== DETAIL PROXY =====
HTTP Proxy: http://${PROXY_USER}:${PROXY_PASS}@${IP_VPS}:${HTTP_PORT}
SOCKS5 Proxy: socks5://${PROXY_USER}:${PROXY_PASS}@${IP_VPS}:${SOCKS_PORT}
=====================================
EOF

echo -e "${GREEN}[+] File proxy.txt berhasil dibuat${NC}"

