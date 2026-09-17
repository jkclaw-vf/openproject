# Build & local smoke — 17.8.0-vf.1

Run from repo root on the branch that contains `modules/vf_auth` (publish tip or local `vf/release-17.8`).

## 1. Record source commit
```bash
git rev-parse HEAD
git log -1 --oneline
```

## 2. Build exact image
```bash
docker build -f docker/prod/Dockerfile -t valuefusion/openproject:17.8.0-vf.1 .
docker image inspect valuefusion/openproject:17.8.0-vf.1 \
  --format 'Id={{.Id}} RepoDigests={{json .RepoDigests}} Created={{.Created}}'
```

## 3. Prove module is in the image (no Entra secrets required)
```bash
docker run --rm valuefusion/openproject:17.8.0-vf.1 \
  bash -lc 'bundle show openproject-vf_auth && test -d /app/modules/vf_auth && grep vf_auth /app/Gemfile.modules && echo OK'
```

## 4. Local compose smoke (non-production)

Prefer a disposable compose project (copy `docker/vf/docker-compose.vf.example.yml` patterns) **or** a side stack that does **not** point at prod volumes.

Minimum checks without Entra env (SSO stays inactive — B11):

```bash
# After stack is up with image valuefusion/openproject:17.8.0-vf.1 on web+worker+cron:
docker compose ps
curl -fsS -o /dev/null -w '%{http_code}\n' http://127.0.0.1:8080/login
# local admin login via browser
# API smoke with an existing token / basic auth as you already use
curl -fsS -H "Authorization: Bearer $OP_TOKEN" http://127.0.0.1:8080/api/v3 | head -c 200; echo
```

With Entra **unset**, login page must **not** require Microsoft; internal login must work.

## 5. Freeze callback (after web is healthy)
```bash
docker exec <web-container> bash -lc \
  'bundle exec rails runner "puts OpenProject::VfAuth::Configuration.callback_path"'
# Expect: /auth/vf_entra/callback
```

Also confirm:
- request: `/auth/vf_entra`
- callback: `/auth/vf_entra/callback`

**Do not** create the Entra app redirect until this prints the expected path on the built image.

## 6. Fill release manifest
Edit `docs/vf/releases/17.8.0-vf.1.yml` with:
- `vf_source_commit`
- `docker_image_id`
- `docker_digest`
- `built_at`

## Acceptance map

| ID | Check |
|---|---|
| B1 | boots |
| B2 | migrations OK |
| B3–B5 | web/worker/cron healthy, same image id |
| B6 | local admin login |
| B7 | projects/WPs intact (if using copied data; else N/A on fresh DB) |
| B8 | API v3 smoke |
| B9 | `vf_auth` present in image; callback path frozen |
| B10 | no Enterprise SSO entitlement required |
| B11 | boots with incomplete `VF_ENTRA_*` |
| B12 | manifest filled |
