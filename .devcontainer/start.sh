#!/bin/sh

# Lancer PHP-FPM en arrière-plan
php-fpm -D

# Lancer Caddy en avant-plan (doit être le processus principal)
exec caddy run --config /etc/caddy/Caddyfile --adapter caddyfile