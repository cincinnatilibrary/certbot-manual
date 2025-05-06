# Sierra SSL Certificate Renewal Run‑Book

_Last updated: **May 6 2025**_

This document captures the **exact, tested procedure** for refreshing WebPAC / Encore certificates on Sierra hosts.  
It reflects fixes discovered on **sierra‑test‑rSierra 6.4.0_4** _and_ **sierra‑train‑rSierra 6.3.0_10**.

---

## 0  Environment & Key Paths

| Purpose | Path |
|---------|------|
| Working directory while logged in as you | `/iiidb/work/rvoelker/` |
| Primary cert file read by `checkcert` | `/iiidb/http/screens/webpac.crt` |
| Private key location | `/iiidb/ssl/cert/webpac.key` |
| Additional product trees (if present) | `/iiidb/http/{live,staging}/screens`<br>`/iiidb/httpkids/{live,staging}/screens`<br>`/iiidb/http_wpmobile/screens`<br>`/iiidb/http_encore/live/screens` |

---

## 1  Issue / Renew the Certificate (off ‑box)

```bash
docker run --rm -it \
  -v "$(pwd)/config:/etc/letsencrypt" \
  -v "$(pwd)/work:/var/lib/letsencrypt" \
  -v "$(pwd)/logs:/var/log/letsencrypt" \
  -v "$(pwd)/secrets/cloudflare.ini:/secrets/cloudflare.ini" \
  certbot/dns-cloudflare certonly \
     --dns-cloudflare \
     --dns-cloudflare-credentials /secrets/cloudflare.ini \
     --dns-cloudflare-propagation-seconds 30 \
     --cert-name cincinnatilibrary.org \
     -d cincinnatilibrary.org -d "*.cincinnatilibrary.org" \
     --key-type rsa --rsa-key-size 4096 \
     --non-interactive --agree-tos \
     --email ilshelp@chpl.org
```

**Resulting files** (inside `config/live/cincinnatilibrary.org/`):

| Let’s Encrypt output | Copy / paste into Sierra |
|----------------------|--------------------------|
| `fullchain.pem` | `/iiidb/work/rvoelker/new.webpac.crt` |
| `privkey.pem`   | `/iiidb/work/rvoelker/new.webpac.key` |

> **Shortcut:** open the PEMs in a text editor and paste their contents into the destination files on the Sierra host.

---

## 2  Verify Key ↔ Cert Pair

```tcsh
cd /iiidb/work/rvoelker
openssl x509 -noout -modulus -in new.webpac.crt | openssl md5
openssl rsa  -noout -modulus -in new.webpac.key | openssl md5   # must match
checkcert -v -c new.webpac.crt -k new.webpac.key
```

---

## 3  Back‑up Existing Cert & Key  (ticket ID `07999144`)

```tcsh
set ticnum = "07999144"
find /iiidb/http/live/screens -depth -name "*.crt"        \
     -exec sh -c 'cp -p "$1" "${1%.crt}.crt.NS'$ticnum'"' _ {} \;
find /iiidb/ssl/cert -depth -name "*.key"                 \
     -exec sh -c 'cp -p "$1" "${1%.key}.key.NS'$ticnum'"' _ {} \;
```

---

## 4  Deploy New **Certificate**

```tcsh
set SRC_CRT = /iiidb/work/rvoelker/new.webpac.crt
mkdir -p /iiidb/http/screens       # ensure default path exists

foreach d ( /iiidb/http/screens                               \
            /iiidb/http/live/screens /iiidb/http/staging/screens \
            /iiidb/httpkids/live/screens /iiidb/httpkids/staging/screens \
            /iiidb/http_wpmobile/screens /iiidb/http_encore/live/screens )
    if ( -d $d ) then
        cp -v "$SRC_CRT" "$d/webpac.crt"
        chown iii:iii "$d/webpac.crt"
    endif
end
```

---

## 5  Install New **Private Key**

```tcsh
cp -v /iiidb/work/rvoelker/new.webpac.key /iiidb/ssl/cert/webpac.key
chown iii:iii /iiidb/ssl/cert/webpac.key
```

---

## 6  Run Final Consistency Check

```tcsh
checkcert -v     # expect “certificate and private key match”
```

---

## 7  Activate the New Bundle

```bash
su - iiiroot
stoppac -mi          # orderly shutdown
exit                 # back to root
shutdown -r now      # full reboot
```

All middleware restarts automatically and loads the fresh certificate.

---

## 8  Post‑reboot Validation

```tcsh
openssl s_client -connect catalog.cincinnatilibrary.org:443 \
                 -servername catalog.cincinnatilibrary.org </dev/null | \
  openssl x509 -noout -dates -subject -issuer
# verify new Not After date
```

---

## 9  Troubleshooting

| Symptom | Resolution |
|---------|------------|
| `No such file or directory` for `webpac.crt` | Ensure `/iiidb/http/screens` exists & copy the cert there. |
| `key values mismatch` | Copy the matching key and `chown iii:iii`. |
| `junction restart … may not be executed by root` | `su - iii` first, or reboot. |

---


