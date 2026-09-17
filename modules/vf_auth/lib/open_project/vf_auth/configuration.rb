# frozen_string_literal: true

module OpenProject
  module VfAuth
    # Reads non-secret and secret Entra configuration from process environment.
    # Secrets must never be committed; prefer /etc/valuefusion/openproject-secrets.env.
    class Configuration
      TENANT_ID_KEY = "VF_ENTRA_TENANT_ID"
      CLIENT_ID_KEY = "VF_ENTRA_CLIENT_ID"
      CLIENT_SECRET_KEY = "VF_ENTRA_CLIENT_SECRET"
      ISSUER_KEY = "VF_ENTRA_ISSUER"
      DISPLAY_NAME_KEY = "VF_ENTRA_PROVIDER_NAME"

      class << self
        def enabled?
          tenant_id.present? && client_id.present? && client_secret.present?
        end

        def tenant_id
          ENV[TENANT_ID_KEY].to_s.strip.presence
        end

        def client_id
          ENV[CLIENT_ID_KEY].to_s.strip.presence
        end

        def client_secret
          ENV[CLIENT_SECRET_KEY].to_s.strip.presence
        end

        def display_name
          ENV.fetch(DISPLAY_NAME_KEY, "Microsoft").to_s.strip.presence || "Microsoft"
        end

        def issuer
          explicit = ENV[ISSUER_KEY].to_s.strip.presence
          return explicit if explicit
          return nil if tenant_id.blank?

          "https://login.microsoftonline.com/#{tenant_id}/v2.0"
        end

        def callback_path
          "/auth/#{OpenProject::VfAuth::PROVIDER_SLUG}/callback"
        end

        def authorization_origin
          "https://login.microsoftonline.com"
        end

        def to_omniauth_options
          raise ArgumentError, "VF Entra is not configured" unless enabled?

          {
            name: OpenProject::VfAuth::PROVIDER_SLUG,
            scope: %i[openid profile email],
            response_type: :code,
            discovery: true,
            issuer:,
            send_nonce: true,
            client_options: {
              identifier: client_id,
              secret: client_secret,
              host: "login.microsoftonline.com",
              scheme: "https",
              port: 443
            }
          }
        end
      end
    end
  end
end
