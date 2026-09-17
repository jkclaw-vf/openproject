# frozen_string_literal: true

require "open_project/plugins"
require "open_project/vf_auth/configuration"
require "omniauth/strategies/vf_entra"

module OpenProject
  module VfAuth
    class Engine < ::Rails::Engine
      engine_name :openproject_vf_auth

      include OpenProject::Plugins::ActsAsOpEngine

      register "openproject-vf_auth",
               author_url: "https://valuefusion.com",
               bundled: true,
               requires_openproject: ">= 17.8.0"

      patches %i[OmniAuthStartController]

      # Independent OmniAuth registration — does NOT use AuthPlugin.register_auth_providers
      # and therefore does not pass through EnterpriseToken sso_auth_providers filtering.
      initializer "openproject_vf_auth.omniauth", before: :build_middleware_stack do |app|
        next unless OpenProject::VfAuth::Configuration.enabled?

        options = OpenProject::VfAuth::Configuration.to_omniauth_options
        app.config.middleware.use OmniAuth::Builder do
          provider OmniAuth::Strategies::VfEntra, options
        end
      end

      config.to_prepare do
        ::OpenProject::VfAuth::Hooks

        ensure_auth_provider_record! if OpenProject::VfAuth::Configuration.enabled?
      end

      class << self
        def ensure_auth_provider_record!
          PluginAuthProvider.find_or_create_by!(slug: OpenProject::VfAuth::PROVIDER_SLUG) do |provider|
            provider.display_name = OpenProject::VfAuth::Configuration.display_name
            provider.available = true
            provider.creator = User.system
          end.tap do |provider|
            attrs = {
              display_name: OpenProject::VfAuth::Configuration.display_name,
              available: true
            }
            provider.update!(attrs) if attrs.any? { |k, v| provider.public_send(k) != v }
          end
        rescue StandardError => e
          Rails.logger.error { "[vf_auth] Failed to ensure AuthProvider record: #{e.class}: #{e.message}" }
        end
      end
    end
  end
end
