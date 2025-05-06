# Sierra SSL Certificate Renewal Run‑Book

_Last updated: **May 6 2025**_

This document records the exact procedure (and fixes) used to refresh the WebPAC/Encore certificates on **sierra‑test‑rSierra 6.4.0_4**.  
Keep it with your change‑control records.

---

## 0  Environment & Paths

| Item | Value |
|------|-------|
| Working directory on **Sierra host** | `/iiidb/work/rvoelker/` |
| Default cert path searched by `checkcert` | `/iiidb/http/screens/webpac.crt` |
| Default key path | `/iiidb/ssl/cert/webpac.key` |
| Extra product paths that also need the cert | `/iiidb/http/{live,staging}/screens`, `/iiidb/httpkids/{live,staging}/screens`, `/iiidb/http_wpmobile/screens`, `/iiidb/http_encore/live/screens` |

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

*Resulting files (inside `config/live/cincinnatilibrary.org/`)*  

| File | Copied to |
|------|-----------|
| `privkey.pem`         | `/iiidb/work/rvoelker/new.webpac.key` |
| `fullchain.pem`       | `/iiidb/work/rvoelker/new.webpac.crt` |

> **Shortcut we used:** opened `fullchain.pem` & `privkey.pem` in a text editor and simply pasted their contents into the destination files instead of `scp`.

---

## 2  Validate Key ↔ Cert Locally

```tcsh
cd /iiidb/work/rvoelker
# quick modulus check
openssl x509 -noout -modulus -in new.webpac.crt | openssl md5
openssl rsa  -noout -modulus -in new.webpac.key | openssl md5
# should output identical hashes

checkcert -v -c new.webpac.crt -k new.webpac.key
```

---

## 3  Back‑up Existing Files (ticket ID example `07999144`)

```tcsh
set ticnum = "07999144"
find /iiidb/http/live/screens -depth -name "*.crt" \
     -exec sh -c 'cp -p "$1" "${1%.crt}.crt.NS'$ticnum'"' _ {} \;
find /iiidb/ssl/cert -depth -name "*.key" \
     -exec sh -c 'cp -p "$1" "${1%.key}.key.NS'$ticnum'"' _ {} \;
```

---

## 4  Deploy the New Certificate

```tcsh
set SRC_CRT = /iiidb/work/rvoelker/new.webpac.crt
echo /iiidb/http/{live,staging}/screens \
     /iiidb/httpkids/{live,staging}/screens \
     /iiidb/http_wpmobile/screens \
     /iiidb/http_encore/live/screens \
     /iiidb/http/screens | \
xargs -n1 -I{} cp -v "$SRC_CRT" {}
```

**Fix applied:**  
*We added `/iiidb/http/screens` to cover the default lookup used by `checkcert`.*

---

## 5  Install the Private Key

```tcsh
cp -v /iiidb/work/rvoelker/new.webpac.key /iiidb/ssl/cert/webpac.key
```

---

## 6  Final Consistency Check

```tcsh
checkcert -v
# should report “certificate and private key match”
```

> **Problem solved:** earlier failures were due to  
> 1. missing `/iiidb/http/screens/webpac.crt`  
> 2. stale key that didn’t match the new cert.

---

## 7  Restart to Activate

Because some wrapper scripts refused to run as `root`, we performed a **full reboot**:

```bash
su - iiiroot
stoppac -mi          # shuts down middleware cleanly
exit                 # back to root
shutdown -r now
```

_All services (WebPAC, Tomcat, Junction) auto‑started on boot and loaded the fresh cert._

---

## 8  Post‑restart Verification

```tcsh
# as any user
openssl s_client -connect catalog.cincinnatilibrary.org:443 -servername catalog.cincinnatilibrary.org </dev/null |   openssl x509 -noout -dates -subject -issuer

# Browser padlock check – OK
```

---

## 9  Troubleshooting Cheatsheet

| Error | Fix |
|-------|-----|
| `No such file or directory` for `/iiidb/http/screens/webpac.crt` | Copy cert into that exact directory or add the directory to the cert‑deploy list. |
| `X509_check_private_key:key values mismatch` | Key & cert do not belong together – re‑export matching pair from Certbot. |
| `junction restart … may not be executed by root` | `su - iii` first, then run the restart. |
| Wrapper refuses reload | Kill the PID (`is '[w]ebpac' | awk '{print "kill -9",$2}' \| sh`) and let it respawn, or reboot. |

---
