#!/bin/sh

cd "$(dirname "$0")"
read -p "Enter Domain You Would Like To Renew: " domain
sudo certbot renew
sudo cp "/etc/letsencrypt/live/${domain}/cert.pem" ./
sudo cp "/etc/letsencrypt/live/${domain}/privkey.pem" ./key.pem
sudo cp "/etc/letsencrypt/live/${domain}/chain.pem" ./
sudo cp "/etc/letsencrypt/live/${domain}/fullchain.pem" ./
