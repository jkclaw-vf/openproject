# VF Divergence Ledger

Track every Value Fusion deviation from upstream OpenProject Community.

## Active divergences

### VF-001 — Microsoft Entra Community SSO (`modules/vf_auth`)

| Field | Value |
|---|---|
| Purpose | Production Microsoft Entra OIDC login without Enterprise `sso_auth_providers` entitlement |
| Changed upstream surface | `Gemfile.modules` (add gem); new module only; narrow patch of `OmniAuthStartController` via engine `patches` |
| Why not Enterprise path | Enterprise OIDC UI/engine is gated; card forbids enabling gated modules / copying EE implementation / flipping `filtered_strategy?` to expose EE providers |
| Approach | Independent `OmniAuth::Builder` + `OmniAuth::Strategies::VfEntra` reusing bundled `omniauth-openid-connect`; login button via VF hook; AuthProvider row via `PluginAuthProvider` for linking |
| Upgrade impact | Re-test OmniAuth callback, start controller patch, gem load on each upstream 17.x bump |
| Tests | `modules/vf_auth/spec/**` |
| Rollback | Remove gem from `Gemfile.modules`, rebuild image without module, unset `VF_ENTRA_*`; local login remains |

### VF-002 — Exact VF container image pin

| Field | Value |
|---|---|
| Purpose | Stop floating `17-slim` in production |
| Changed upstream surface | `docker/vf/README.md`, `docker/vf/docker-compose.vf.example.yml`; image built via `docker/prod/Dockerfile` on VF branch |
| Upgrade impact | Rebuild `valuefusion/openproject:<version>-vf.N` per release |
| Tests | Image smoke: web/worker/cron same digest |
| Rollback | Revert compose to previous VF image tag or last known `openproject/openproject@sha256:…` |

## Explicit non-divergences

- Do **not** patch `OpenProject::Plugins::AuthPlugin.filtered_strategy?`
- Do **not** enable `modules/openid_connect` admin UI without entitlement
- Do **not** copy Enterprise provider models/services into Community
- Do **not** implement JWKS/crypto by hand
