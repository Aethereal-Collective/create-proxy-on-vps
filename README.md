# Proxy Server Installer

Script untuk instalasi dan konfigurasi otomatis server proxy HTTP/HTTPS dan SOCKS5.

## Fitur

- Instalasi otomatis Squid (HTTP/HTTPS proxy)
- Instalasi otomatis Dante (SOCKS5 proxy)
- Konfigurasi autentikasi dengan username dan password
- Pembukaan port pada firewall
- Konfigurasi DNS Google dan Cloudflare
- Pembuatan file proxy.txt berisi detail koneksi

## Persyaratan Sistem

- Sistem operasi: Debian12 (Tested)
- Akses root
- VPS dengan IP publik

## Cara Instalasi

1. Download script menggunakan perintah:

```bash
curl -O https://raw.githubusercontent.com/Aethereal-Collective/create-proxy-on-vps/main/install.sh
```

2. Edit script jika diperlukan menggunakan sed (opsional):

```bash
sed -i 's/\r$//' install.sh
```

3. Berikan izin eksekusi pada script:

```bash
chmod +x install.sh
```

4. Jalankan script instalasi:

```bash
./install.sh
```

5. Ikuti petunjuk dalam script untuk mengonfigurasi:
   - IP VPS Anda
   - Username proxy (default: aethereal)
   - Password proxy (default: aethereal)
   - Port HTTP (default: 8080)
   - Port SOCKS (default: 1080)

## Setelah Instalasi

Setelah instalasi selesai, detail proxy Anda akan ditampilkan di terminal dan disimpan dalam file `proxy.txt`.

Format koneksi:
- HTTP Proxy: http://username:password@ip_vps:port_http
- SOCKS5 Proxy: socks5://username:password@ip_vps:port_socks

## Pemecahan Masalah

- Periksa status layanan Squid: `systemctl status squid`
- Periksa status layanan Dante: `systemctl status danted`
- Periksa log Squid: `tail -f /var/log/squid/access.log`
- Periksa log Dante: `tail -f /var/log/danted.log`