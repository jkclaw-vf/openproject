# frozen_string_literal: true

module OpenProject::VfAuth::Patches
  module OmniAuthStartControllerPatch
    def self.included(base)
      base.prepend InstanceMethods
    end

    module InstanceMethods
      private

      def permitted_omniauth_provider_name(name)
        requested = name.to_s
        if requested == OpenProject::VfAuth::PROVIDER_SLUG && OpenProject::VfAuth.enabled?
          return requested
        end

        super
      end

      def append_omniauth_form_action(provider_name)
        super
        return unless provider_name.to_s == OpenProject::VfAuth::PROVIDER_SLUG

        append_content_security_policy_directives(
          form_action: [OpenProject::VfAuth::Configuration.authorization_origin]
        )
      end
    end
  end
end
