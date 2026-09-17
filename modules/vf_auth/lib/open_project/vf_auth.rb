# frozen_string_literal: true

require "open_project/vf_auth/configuration"

module OpenProject
  module VfAuth
    # Defined before Engine load; OmniAuth strategy reads this at require time.
    PROVIDER_SLUG = "vf_entra"

    class << self
      def enabled?
        Configuration.enabled?
      end

      def provider_slug
        PROVIDER_SLUG
      end
    end
  end
end

require "open_project/vf_auth/engine"
