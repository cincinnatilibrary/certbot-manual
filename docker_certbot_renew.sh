docker run -it --rm \
  -v "$(pwd)/config:/etc/letsencrypt" \
  -v "$(pwd)/logs:/var/log/letsencrypt" \
  -v "$(pwd)/work:/var/lib/letsencrypt" \
  -v "$(pwd)/secrets/cloudflare.ini:/secrets/cloudflare.ini" \
  certbot/dns-cloudflare renew
