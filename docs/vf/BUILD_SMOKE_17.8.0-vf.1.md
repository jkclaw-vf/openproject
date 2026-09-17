# Build & local smoke — 17.8.0-vf.1

## Authority (Primary)

- Enterprise SSO gate remains **intact and unused**.
- `vf_auth` is an **independent VF-owned Community** path (generic OmniAuth/OIDC).
- **STOP** if implementation modifies `filtered_strategy?` or otherwise circumvents EE gating.
- Builder must build from an **exact published thin commit**, never an uncommitted VM tree.
- B12 provenance is **mandatory** before Entra registration.

## Pipeline (required order)

```
CHEAP    syntax / Zeitwerk / targeted vf_auth checks
MEDIUM   module load / Rails boot where practical
COMMIT + publish thin VF tip
EXPENSIVE  builder checks out exact commit → Docker image
SMOKE    B1–B6, B9–B12
FREEZE   runtime callback
STOP     Entra app registration
```

## 0. Cheap checks (before Docker)

From repo root on the commit you intend to publish:

```bash
# no AuthPlugin / filtered_strategy? usage (B10 evidence)
! grep -RInE 'filtered_strategy\?|register_auth_providers|EnterpriseToken' modules/vf_auth \
  || { echo "STOP: EE-gate surface touched"; exit 1; }

ruby -c modules/vf_auth/lib/open_project/vf_auth.rb
ruby -c modules/vf_auth/lib/open_project/vf_auth/engine.rb
ruby -c modules/vf_auth/lib/omniauth/strategies/vf_entra.rb

# inflection present
grep -q 'class_inflection_override("omniauth" => "OmniAuth")' \
  modules/vf_auth/lib/open_project/vf_auth/engine.rb

# PROVIDER_SLUG before engine require
ruby -e '
  s = File.read("modules/vf_auth/lib/open_project/vf_auth.rb")
  abort("PROVIDER_SLUG after engine require") if s.index("PROVIDER_SLUG") > s.index("vf_auth/engine")
  puts "load-order OK"
'

# targeted tests if bundle available
bundle exec rspec modules/vf_auth/spec --format progress
```

## 1. Commit + publish thin tip

Publish all qualified VF fixes first. Record:

```bash
git rev-parse HEAD   # → vf_source_commit
```

Builder: `git fetch && git checkout <that-sha>` — clean tree only.

## 2. Build exact image (from published commit)

```bash
docker build -f docker/prod/Dockerfile \
  --build-arg BUNDLE_JOBS=4 \
  -t valuefusion/openproject:17.8.0-vf.1 .

docker image inspect valuefusion/openproject:17.8.0-vf.1 \
  --format 'Id={{.Id}} RepoDigests={{json .RepoDigests}} Created={{.Created}}'
```

## 3. Prove module in image (B9; no Entra secrets)

```bash
docker run --rm valuefusion/openproject:17.8.0-vf.1 \
  bash -lc 'bundle show openproject-vf_auth && test -d /app/modules/vf_auth && grep vf_auth /app/Gemfile.modules && echo OK'
```

## 4. Smoke (non-production; no VF_ENTRA_*)

**Preferred (GCP amd64 VM):** follow [`GCP_SMOKE_SETUP.md`](GCP_SMOKE_SETUP.md) — Caddy on **:80**, OpenProject behind it, access via VM external IP (same firewall pattern as other VF hosts). Do not expose `:8080` to the internet.

Disposable compose. Require `SECRET_KEY_BASE` (not Dockerfile `OVERWRITE_ME`).

```bash
# On the smoke VM after Caddy setup (see GCP_SMOKE_SETUP.md):
curl -fsS -o /dev/null -w '%{http_code}\n' -H "Host: ${VM_IP}" http://127.0.0.1/login   # expect 200
# B6 local admin login in browser: http://<VM_IP>/login
# B11: no Microsoft button required when VF_ENTRA_* unset
```

## 5. Freeze callback (runtime-proven)

```bash
docker compose exec openproject bash -lc \
  'bundle exec rails runner "puts OpenProject::VfAuth::Configuration.callback_path"'
# Expect: /auth/vf_entra/callback
```

**Do not** register Entra redirect until this is proven on the built image.

## 6. B12 release manifest (mandatory)

Fill `docs/vf/releases/17.8.0-vf.1.yml`:

- `upstream_version` / `upstream_commit`
- `vf_source_commit` (thin published SHA)
- `docker_image` / `docker_image_id` / `docker_digest`
- `built_at`

## Acceptance map

| ID | Check |
|---|---|
| B1 | boots |
| B2 | migrations OK |
| B3–B5 | web/worker/cron healthy, same image id |
| B6 | local admin login |
| B7 | projects/WPs intact (if copied data; else N/A on fresh DB) |
| B8 | API v3 smoke |
| B9 | `vf_auth` present; callback path frozen |
| B10 | EE SSO gate unused; no `filtered_strategy?` / AuthPlugin registration |
| B11 | boots with incomplete `VF_ENTRA_*` |
| B12 | release manifest complete (exact commit + image id + digest) |
