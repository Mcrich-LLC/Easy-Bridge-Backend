@echo off

cd /D "%~dp0"
certbot renew --dry-run
copy /Y C:\Certbot\live\mc.mcrich23.com\privkey.pem key.pem
copy /Y C:\Certbot\live\mc.mcrich23.com\fullchain.pem fullchain.pem
copy /Y C:\Certbot\live\mc.mcrich23.com\chain.pem chain.pem
copy /Y C:\Certbot\live\mc.mcrich23.com\cert.pem cert.pem
pause