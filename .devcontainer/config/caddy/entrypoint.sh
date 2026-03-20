#!/bin/sh
caddy run --config /etc/caddy/Caddyfile &
CADDY_PID=$!

i=0
while [ ! -f /data/caddy/pki/authorities/local/root.crt ] && [ $i -lt 30 ]; do
  sleep 1
  i=$((i+1))
done

if [ -f /data/caddy/pki/authorities/local/root.crt ]; then
  cp /data/caddy/pki/authorities/local/root.crt /export/root.crt
  chmod 644 /export/root.crt
fi

if [ -f /data/caddy/pki/authorities/local/intermediate.crt ]; then
  cp /data/caddy/pki/authorities/local/intermediate.crt /export/intermediate.crt
  chmod 644 /export/intermediate.crt
fi

wait $CADDY_PID