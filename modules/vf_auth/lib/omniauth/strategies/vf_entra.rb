# frozen_string_literal: true

require "omniauth"
require "omniauth/strategies/openid_connect"

module OmniAuth
  module Strategies
    # Value Fusion Microsoft Entra strategy.
    #
    # Independent of OpenProject Enterprise SSO registration. Reuses the bundled
    # omniauth-openid-connect strategy for authorization-code flow, discovery,
    # JWKS/signature verification, state, and nonce. Does not activate the
    # Enterprise openid_connect provider admin UI.
    class VfEntra < OpenIDConnect
      option :name, OpenProject::VfAuth::PROVIDER_SLUG

      uid do
        identity = durable_identity!
        "#{identity[:tid]}:#{identity[:oid]}"
      end

      info do
        identity = durable_identity!
        claims = id_token_claims

        {
          email: preferred_email(claims),
          login: preferred_login(claims),
          first_name: claims["given_name"].presence || split_name(claims["name"]).first,
          last_name: claims["family_name"].presence || split_name(claims["name"]).last,
          name: claims["name"],
          uid: "#{identity[:tid]}:#{identity[:oid]}"
        }.compact
      end

      def request_phase
        ensure_configured!
        ensure_tenant_issuer!
        super
      end

      def callback_phase
        ensure_configured!
        ensure_tenant_issuer!
        super
      rescue MissingIdentityError => e
        fail!(:vf_entra_missing_identity, e)
      rescue TenantMismatchError => e
        fail!(:vf_entra_tenant_mismatch, e)
      end

      private

      def ensure_configured!
        return if OpenProject::VfAuth::Configuration.enabled?

        raise OmniAuth::Strategies::OpenIDConnect::CallbackError.new(
          "vf_entra_not_configured",
          "Value Fusion Entra authentication is not configured"
        )
      end

      def ensure_tenant_issuer!
        expected = OpenProject::VfAuth::Configuration.issuer
        actual = options.issuer.to_s
        return if expected.present? && actual == expected

        # Before discovery, issuer may still be the configured value only.
        options.issuer = expected if options.issuer.blank? && expected.present?
      end

      def durable_identity!
        claims = id_token_claims
        tid = claims["tid"].to_s.presence
        oid = claims["oid"].to_s.presence

        raise MissingIdentityError, "missing tid claim" if tid.blank?
        raise MissingIdentityError, "missing oid claim" if oid.blank?

        expected_tenant = OpenProject::VfAuth::Configuration.tenant_id
        raise TenantMismatchError, "tid does not match configured tenant" if tid != expected_tenant

        { tid:, oid: }
      end

      def id_token_claims
        token = id_token
        raise MissingIdentityError, "missing id_token" if token.nil?

        raw =
          if token.respond_to?(:raw_attributes)
            token.raw_attributes
          elsif token.respond_to?(:as_json)
            token.as_json
          else
            {}
          end

        raw.with_indifferent_access
      end

      def preferred_email(claims)
        claims["email"].presence || claims["preferred_username"].presence
      end

      def preferred_login(claims)
        claims["preferred_username"].presence || preferred_email(claims)
      end

      def split_name(name)
        parts = name.to_s.strip.split(/\s+/, 2)
        [parts[0], parts[1]]
      end

      class MissingIdentityError < StandardError; end
      class TenantMismatchError < StandardError; end
    end
  end
end

OmniAuth.config.add_camelization "vf_entra", "VfEntra"
