# GCP smoke host — Value Fusion OpenProject (rerun guide)

Disposable qualification stack for `valuefusion/openproject:17.8.0-vf.1`.
**Not** production (`pm.valuefusion.com` / `openproject-pilot`).

Proven working pattern (2026-09-17):

- All-in-one OpenProject container (embedded Postgres)
- **Caddy on host port 80** → reverse proxy to OpenProject
- Public access via VM **external IP** on **HTTP :80** (same firewall shape as other VF VMs)
- No Entra env vars during smoke (SSO inactive — B11)

---

## Prerequisites

| Item | Notes |
|---|---|
| GCP VM | amd64 Ubuntu (e.g. `openproject-dev`) |
| Docker Engine + Compose plugin | `docker` / `docker compose` without sudo (user in `docker` group) |
| Image | `valuefusion/openproject:17.8.0-vf.1` already built on this host (or loaded) |
| Network tag | VM must include **`http-server`** so `default-allow-http` (tcp:80) applies |
| Firewall | Ingress tcp:80 to `http-server` (or equivalent). Do **not** rely on :8080 from the internet |

Optional: tag `openproject` if you use custom allow-all rules; **port 80 + `http-server`** is what matched production-style access.

---

## One-time: image present

```bash
docker image inspect valuefusion/openproject:17.8.0-vf.1 \
  --format 'Id={{.Id}} Created={{.Created}}'
```

If missing, rebuild from an **exact published thin commit** (see `docs/vf/BUILD_SMOKE_17.8.0-vf.1.md` — never from a dirty uncommitted tree).

---

## Setup (copy-paste)

SSH to the GCP VM as your normal user (not Mac localhost).

```bash
mkdir -p ~/vf-smoke && cd ~/vf-smoke

# stable secret for this smoke volume (keep the file; reuse across recreates)
openssl rand -hex 64 > .secret_key_base
chmod 600 .secret_key_base

# external IP of THIS vm
export VM_IP="$(curl -s -H 'Metadata-Flavor: Google' \
  http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/access-configs/0/external-ip)"
echo "VM_IP=${VM_IP}"
# must look like 34.x.x.x or 104.x.x.x — never a placeholder string

export SECRET_KEY_BASE="$(cat .secret_key_base)"

cat > Caddyfile <<EOF
http://${VM_IP} {
  reverse_proxy openproject:80
}
EOF

cat > docker-compose.yml <<EOF
services:
  openproject:
    image: valuefusion/openproject:17.8.0-vf.1
    expose:
      - "80"
    environment:
      SECRET_KEY_BASE: "${SECRET_KEY_BASE}"
      OPENPROJECT_HOST__NAME: "${VM_IP}"
      OPENPROJECT_HTTPS: "false"
      # Intentionally no VF_ENTRA_*  → Microsoft SSO inactive (B11)
    volumes:
      - op-pg:/var/openproject/pgdata
      - op-assets:/var/openproject/assets
    networks: [op]

  caddy:
    image: caddy:2
    ports:
      - "80:80"
    volumes:
      - ./Caddyfile:/etc/caddy/Caddyfile:ro
    networks: [op]
    depends_on: [openproject]

networks:
  op:

volumes:
  op-pg:
  op-assets:
EOF

docker compose up -d
```

First boot can take **several minutes** (Postgres + migrate/seed + Puma). Do not judge health in the first ~30s.

---

## Network tag (if browser times out)

GCP Console → VM → Edit → **Network tags** → ensure:

`http-server`

Save. Confirm firewall has ingress **tcp:80** for that tag (e.g. `default-allow-http`).

---

## Verify

**On the VM:**

```bash
cd ~/vf-smoke
docker compose ps
docker compose logs --tail=40 openproject   # wait for Puma "Listening"

curl -sS -o /dev/null -w '%{http_code}\n' \
  -H "Host: ${VM_IP}" \
  http://127.0.0.1/login
# expect 200
```

**From your laptop browser** (not `localhost`, not `:8080`):

```text
http://<VM_IP>/login
```

Complete local admin login / password reset (B6).

**Callback path (runtime):**

```bash
docker compose exec openproject bash -lc \
  'bundle exec rails runner "puts OpenProject::VfAuth::Configuration.callback_path"'
# expect: /auth/vf_entra/callback
```

Path is what we freeze. Production absolute URI later is  
`https://pm.valuefusion.com/auth/vf_entra/callback` — **do not** register Entra until that host runs the VF image.

**API anonymous check:**

```bash
curl -sS -H "Host: ${VM_IP}" http://127.0.0.1/api/v3 | head -c 200; echo
# Unauthenticated JSON error is OK — proves API is up
```

---

## Common failures

| Symptom | Cause | Fix |
|---|---|---|
| Mac `curl 127.0.0.1:8080` fails | Wrong machine | Smoke runs on GCP VM; Mac uses `http://<VM_IP>/` |
| Browser timeout on `:8080` | Port not in prod-like firewall | Use **:80** + Caddy + `http-server` tag |
| HTTP 400 | Host header ≠ `OPENPROJECT_HOST__NAME` | Host must be exactly `<VM_IP>` (no `:8080`) |
| HTTP 503 | App still starting or crash | `docker compose logs -f openproject`; wait for Puma |
| `SECRET_KEY_BASE` / OVERWRITE_ME | Missing env | Must set `SECRET_KEY_BASE` from `.secret_key_base` |
| `VM_IP=<paste-…>` | Placeholder not replaced | Use metadata curl for real IP |

---

## Teardown

```bash
cd ~/vf-smoke
docker compose down
# wipe DB/assets for a clean reseed:
docker compose down -v
```

Keep `~/vf-smoke/.secret_key_base` if you want the same cookie/signing key across recreates **without** `-v`.

---

## What not to do

- Do not point this stack at production volumes or `/opt/openproject` on `openproject-pilot`
- Do not put Entra client secrets on the smoke host unless running SSO UAT
- Do not register the smoke IP as the production Entra redirect URI
- Do not rebuild the image from an uncommitted VM working tree — publish thin tip first (`BUILD_SMOKE_17.8.0-vf.1.md`)

---

## Related

- `docs/vf/BUILD_SMOKE_17.8.0-vf.1.md` — build pipeline, B1–B12, provenance
- `docs/vf/releases/17.8.0-vf.1.yml` — release manifest
- `docs/vf/ENTRA_SSO_SETUP.md` — Entra app (after callback proven on the deploy host)
