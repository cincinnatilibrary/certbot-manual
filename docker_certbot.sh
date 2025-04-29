#!/bin/bash

docker run -it --rm \
  -v "$(pwd)/config:/etc/letsencrypt" \
  -v "$(pwd)/logs:/var/log/letsencrypt" \
  -v "$(pwd)/work:/var/lib/letsencrypt" \
  -v "$(pwd)/secrets/cloudflare.ini:/secrets/cloudflare.ini" \
  certbot/dns-cloudflare certonly \
  --dns-cloudflare \
  --dns-cloudflare-credentials /secrets/cloudflare.ini \
  --dns-cloudflare-propagation-seconds 30 \
  --key-type rsa \
  --rsa-key-size 4096 \
  --cert-name cincinnatilibrary.org \
  -d cincinnatilibrary.org \
  -d '*.cincinnatilibrary.org' \
  --non-interactive \
  --agree-tos \
  --email ilshelp@chpl.org # \
  # --dry-run
