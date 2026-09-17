# frozen_string_literal: true

Gem::Specification.new do |s|
  s.name        = "openproject-vf_auth"
  s.version     = "1.0.0"
  s.authors     = "Value Fusion"
  s.email       = "engineering@valuefusion.com"
  s.homepage    = "https://github.com/valuefusion/openproject"
  s.summary     = "Value Fusion Microsoft Entra OIDC authentication"
  s.description = "Independent Community OmniAuth/OIDC integration for Microsoft Entra ID (not Enterprise SSO)."
  s.license     = "GPLv3"

  s.files = Dir["{app,config,lib}/**/*"] + %w[README.md]

  s.add_dependency "openproject-auth_plugins"
  s.metadata["rubygems_mfa_required"] = "true"
end
