# Value Fusion OpenProject Fork Strategy

## Remotes

| Remote | URL | Role |
|---|---|---|
| `upstream` | `https://github.com/opf/openproject.git` | Full upstream history |
| `origin` | `https://github.com/jkclaw-vf/openproject.git` | Thin VF **distribution** history (not a mirror of all OP commits) |

## Branches

| Branch | Role |
|---|---|
| Local `vf/release-17.8` | Development / rebase against upstream tags (may keep full ancestry) |
| `origin/vf/release-17.8` | Published VF distribution tip |
| `origin/vf/main` | Same published tip (integration pointer) |

## Baseline (OP-01)

- Upstream tag: `v17.8.0`
- Upstream commit: `2d1ae9c1f2de49d363e0ec2cea7d7f2991ed405a`
- Production previously: `openproject/openproject:17-slim` @ `sha256:48952034215d2a8ecf07086db86be55c74819cc76aa26af61f8da9ce5f06eda2`
- VF image: `valuefusion/openproject:17.8.0-vf.1` (never floating `:17` / `:17-slim`)

## Distribution history doctrine

GitHub `origin` records **what VF changed and when**, not fifteen years of OpenProject commits.

Ordinary upgrades **must not** recreate orphans / force-push a new root. Append commits:

```
OpenProject v17.8.0 baseline (tree)
  → VF Entra SSO
  → VF branding (later)
  → Upstream baseline update: v17.9.0
  → VF compatibility corrections
  → tag / image 17.9.0-vf.1
```

Local full-ancestry branches may still merge/rebase from `upstream` tags; publish the resulting tree as normal commits onto the thin `origin` history.

## Release manifests

Every shippable image gets `docs/vf/releases/<version>-vf.N.yml`.

## Auth callback (17.8.0 freeze)

| Step | Path |
|---|---|
| Login button | GET `/auth/vf_entra` (OmniAuth request phase via Rack) |
| Callback | `/auth/vf_entra/callback` → `OmniAuthLoginController#callback` |

Absolute production URI (register in Entra **only after** image smoke):

`https://pm.valuefusion.com/auth/vf_entra/callback`

Note: OpenProject **17.8.0** does not use `/login/omniauth/:provider` (that exists on newer `dev`). VF hooks match the 17.8 provider link pattern.

## Mandatory regression

- Login page loads; Microsoft button when `VF_ENTRA_*` complete
- Request `/auth/vf_entra` → callback `/auth/vf_entra/callback`; link `tid:oid`
- Existing OpenProject user id preserved
- Logout = OP session only
- `/login/internal` break-glass
- Work package / API smoke
- Boots with SSO **disabled** when Entra env incomplete (B11)
