# frozen_string_literal: true

module OpenProject
  module VfAuth
    class Hooks < OpenProject::Hook::ViewListener
      render_on :view_account_login_auth_provider,
                partial: "hooks/login/vf_entra"
    end
  end
end
