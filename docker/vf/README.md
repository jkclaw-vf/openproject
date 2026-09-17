# VF production image build notes

## Required tag

`valuefusion/openproject:17.8.0-vf.1`

Never deploy floating `openproject/openproject:17` or `:17-slim` after cutover.

## Build

On branch `vf/release-17.8` (upstream `v17.8.0` + VF commits):

```bash
docker build -f docker/prod/Dockerfile -t valuefusion/openproject:17.8.0-vf.1 .
docker image inspect valuefusion/openproject:17.8.0-vf.1 --format '{{.Id}} {{json .RepoDigests}}'
```

There is no separate VF Dockerfile: upstream `docker/prod/Dockerfile` already copies `modules/` and loads `Gemfile.modules` (includes `openproject-vf_auth`).

Confirm before push:

```bash
docker run --rm valuefusion/openproject:17.8.0-vf.1 \
  bash -lc 'bundle show openproject-vf_auth && test -d /app/modules/vf_auth && echo OK'
```

## Runtime identity

web, worker, and cron must report the **same** image ID.
