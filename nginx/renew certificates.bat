@echo off

cd /D "%~dp0"
set /p "domain=Enter Domain You Would Like To Renew: "
certbot renew --dry-run
copy /Y C:\Certbot\live\%domain%\privkey.pem key.pem
copy /Y C:\Certbot\live\%domain%\fullchain.pem fullchain.pem
copy /Y C:\Certbot\live\%domain%\chain.pem chain.pem
copy /Y C:\Certbot\live\%domain%\cert.pem cert.pem
pause