# certbot-manual

Semi-Automated Let's Encrypt certificate generation using Certbot with the DNS-01 challenge via Cloudflare

## Prerequisites

- Docker installed (e.g. `sudo apt install docker.io`)
- A Cloudflare API Token with `Zone.DNS` permissions

## Secrets

The Cloudflare API Token should be stored in an .ini file:

```bash
mkdir -p secrets
touch secrets/cloudflare.ini
chmod 600 secrets/cloudflare.ini
```

The contents should look similar to this:

```text
# Cloudflare API token used by Certbot
dns_cloudflare_api_token = PLACE_TOKEN_HERE
```

## Issue a certificate
```bash
./docker_certbot.sh
```

This will request a certificate using the DNS-01 challenge and store it in `config/live/cincinnatilibrary.org/`.


## Renewal

To renew your certificate (Certbot will only renew if it's <30 days from expiry):

```bash
./docker_certbot_renew.sh
```

## iii Service Commitment: Set up or renew SSL

Submitting this form to set up or renew an SSL

https://iii.rightanswers.com/portal/app/portlets/results/viewsolution.jsp?solutionid=151209171122621



