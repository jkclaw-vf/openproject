# VF OpenProject upgrade checklist

For every upstream OpenProject bump merged into the VF release branch:

- [ ] Update `docs/VF_DIVERGENCE.md` if surfaces changed
- [ ] `bundle install` / image build succeeds with `openproject-vf_auth`
- [ ] Module loads; `PluginAuthProvider` slug `vf_entra` present when configured
- [ ] Login page shows Microsoft button
- [ ] `/login/omniauth/vf_entra` renders POST form
- [ ] Happy-path Entra callback (staging tenant or recorded fixture)
- [ ] Existing `UserAuthProviderLink` still resolves
- [ ] Uninvited user denied with self-registration disabled
- [ ] Logout OK
- [ ] `/login/internal` break-glass OK
- [ ] Work package create/view API smoke
- [ ] web/worker/cron share one image digest
