# Value Fusion OpenProject Fork Strategy

## Remotes

| Remote | URL |
|---|---|
| `origin` | `https://github.com/valuefusion/openproject.git` (VF fork) |
| `upstream` | `https://github.com/opf/openproject.git` |

## Branches

| Branch | Role |
|---|---|
| `upstream/v17` | Tracking mirror of upstream release/17 line |
| `vf/main` | VF integration branch |
| `vf/release-17.8` | Release line for OpenProject 17.8.x + VF patches |

## Baseline (OP-01)

- Upstream tag: `v17.8.0`
- Upstream commit: `2d1ae9c` (confirm with `git rev-parse v17.8.0`)
- Production previously ran: `openproject/openproject:17-slim` → digest `sha256:48952034215d2a8ecf07086db86be55c74819cc76aa26af61f8da9ce5f06eda2` (17.8.0)
- VF image tag: `valuefusion/openproject:17.8.0-vf.1` (exact pin; never floating `:17` / `:17-slim` in production)

## Upgrade flow

```
upstream v17.x tag
  → merge into vf/release-17.x
  → resolve docs/VF_DIVERGENCE.md items
  → VF regression suite
  → build valuefusion/openproject:<version>-vf.N
  → staging/UAT
  → production
```

## Mandatory regression

- Login page loads; Microsoft button visible when env configured
- Entra auth starts (`/login/omniauth/vf_entra` → POST `/auth/vf_entra`)
- Callback completes; `UserAuthProviderLink` for `vf_entra` + `tid:oid`
- Existing OpenProject user id preserved
- Logout destroys OP session only (no Microsoft global logout)
- `/login/internal` break-glass works
- Work package / API smoke
- VF branding smoke (when present)
