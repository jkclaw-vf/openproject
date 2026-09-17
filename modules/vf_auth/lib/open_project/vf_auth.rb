# frozen_string_literal: true

require "open_project/vf_auth/configuration"
require "open_project/vf_auth/engine"

module OpenProject
  module VfAuth
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
