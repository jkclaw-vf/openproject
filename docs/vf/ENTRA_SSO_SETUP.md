# Microsoft Entra app registration — Value Fusion Project Management

Do **not** register the redirect URI until this runbook matches the deployed VF image.

## Application

- **Name:** Value Fusion Project Management
- **Supported account types:** Accounts in this organizational directory only (single VF tenant)
- **Do not use:** `/common`, `/organizations`, personal Microsoft accounts, multi-tenant

## Protocol

- OIDC authorization code flow
- Client type: confidential web application (client secret)
- PKCE: preferred when the OmniAuth OIDC library supports it; OpenProject 17.8.0 ships `omniauth-openid-connect` **0.5.0** without PKCE. VF relies on **confidential client + state + nonce + ID token issuer/audience/JWKS verification**. Revisit PKCE when upgrading the OIDC strategy gem.

## Redirect URI (exact)

```
https://pm.valuefusion.com/auth/vf_entra/callback
```

Provider start (browser):

```
https://pm.valuefusion.com/login/omniauth/vf_entra
```

(POST then goes to `/auth/vf_entra`.)

## Permissions / scopes

Delegated OIDC scopes only:

- `openid`
- `profile`
- `email`

No Microsoft Graph application permissions required for login.

## OpenProject / Compose environment

Non-secret (compose or config):

```bash
VF_ENTRA_TENANT_ID=<directory-tenant-guid>
VF_ENTRA_CLIENT_ID=<application-client-id>
VF_ENTRA_ISSUER=https://login.microsoftonline.com/<tenant-guid>/v2.0
VF_ENTRA_PROVIDER_NAME=Microsoft
```

Secret (host file, not git):

```bash
# /etc/valuefusion/openproject-secrets.env
# owner root:root mode 0600
VF_ENTRA_CLIENT_SECRET=<secret-value>
```

Also keep existing `SECRET_KEY_BASE` in the same secrets file pattern.

## Identity contract

| Claim | Use |
|---|---|
| `tid` | Must equal `VF_ENTRA_TENANT_ID` or fail closed |
| `oid` | User object id |
| Durable uid | `tid:oid` stored as `UserAuthProviderLink` external id for provider slug `vf_entra` |
| `preferred_username` / `email` | Login/email profile attributes only |

## Logout

OpenProject logout destroys the OpenProject session only. Do not configure Microsoft front-channel logout for V1.

## Secret rotation

1. Create a new client secret in Entra; keep the old secret valid.
2. Update `/etc/valuefusion/openproject-secrets.env`.
3. Recreate web/worker/cron with the same VF image.
4. Smoke-test Microsoft login.
5. Delete the old Entra secret.

## V1 OpenProject settings (after deploy)

- Self-registration: **Disabled**
- Allow remapping of existing users: **Enabled** (trusted single-tenant IdP only)
- Keep password login enabled through UAT; later restrict to break-glass via password policy / internal login
