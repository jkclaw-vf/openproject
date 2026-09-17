# Value Fusion Microsoft Entra authentication for OpenProject Community.

Independent of OpenProject Enterprise SSO (`sso_auth_providers`).

## How it works

1. Registers `OmniAuth::Strategies::VfEntra` via `OmniAuth::Builder` (not `AuthPlugin.register_auth_providers`).
2. Reuses bundled `omniauth-openid-connect` for discovery, code flow, JWKS, state, and nonce.
3. Stable external identity: `vf_entra` + `tid:oid`.
4. Account linking uses existing `UserAuthProviderLink` / `Authentication::OmniauthService`.

## Configuration (environment)

| Variable | Secret? | Purpose |
|---|---|---|
| `VF_ENTRA_TENANT_ID` | no | Single VF Entra tenant GUID |
| `VF_ENTRA_CLIENT_ID` | no | App registration client ID |
| `VF_ENTRA_CLIENT_SECRET` | **yes** | Client secret |
| `VF_ENTRA_ISSUER` | no | Optional; default `https://login.microsoftonline.com/<tenant>/v2.0` |
| `VF_ENTRA_PROVIDER_NAME` | no | Button label override (default Microsoft) |

## Callback URL

`https://<host>/auth/vf_entra/callback`

## V1 account policy

- Disable OpenProject self-registration.
- Enable `oauth_allow_remapping_of_existing_users` only because the IdP is the trusted single VF tenant.
- Uninvited Entra users cannot self-provision when registration is disabled.
