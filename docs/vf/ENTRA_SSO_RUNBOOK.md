# Entra SSO operations runbook

## Pre-deploy backup

1. Backup Postgres and `/var/openproject/assets`.
2. Record current image: `docker inspect openproject-web-1 --format '{{.Image}}'`.
3. Preserve `/opt/openproject/.env` and secrets file paths (no secret values in tickets).
4. Confirm break-glass local admin password works.

## Deploy VF image

1. Build/push `valuefusion/openproject:17.8.0-vf.1`.
2. Point web, worker, cron (and seeder if used) at **that exact tag/digest**.
3. Mount/load `VF_ENTRA_*` including secret via `env_file`.
4. Deploy with **local password login still enabled**.

## UAT checklist

| Step | Expect |
|---|---|
| Login page | "Continue with Microsoft" + internal login |
| Jeffrey / Dave / Vanna | Link to existing OP user; same numeric id; no duplicate |
| Uninvited VF Entra user | No account created |
| Wrong tenant / bad token | Fail closed |
| Logout | OP session cleared; M365 session may remain |
| Break-glass | `/login/internal` still works |

## Rollback

1. Set compose image back to previous digest/tag (stock `openproject/openproject@sha256:489520…` or prior VF tag).
2. Remove or ignore `VF_ENTRA_*` if desired.
3. Recreate containers.
4. Confirm local admin login.

Bindings in `user_auth_provider_links` for `vf_entra` may remain harmlessly if rolling forward again.

## Upgrade checklist

See `docs/vf/FORK_STRATEGY.md` mandatory regression list.
