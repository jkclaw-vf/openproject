# frozen_string_literal: true

require "spec_helper"

RSpec.describe "VF Entra login provider hook", type: :view do
  around do |example|
    keys = %w[VF_ENTRA_TENANT_ID VF_ENTRA_CLIENT_ID VF_ENTRA_CLIENT_SECRET]
    previous = keys.index_with { |k| ENV[k] }
    ENV["VF_ENTRA_TENANT_ID"] = "11111111-1111-1111-1111-111111111111"
    ENV["VF_ENTRA_CLIENT_ID"] = "client"
    ENV["VF_ENTRA_CLIENT_SECRET"] = "secret"
    example.run
  ensure
    previous.each { |k, v| v.nil? ? ENV.delete(k) : ENV[k] = v }
  end

  it "renders a direct OmniAuth start link for vf_entra" do
    render partial: "hooks/login/vf_entra"
    expect(rendered).to include("Continue with Microsoft")
    expect(rendered).to include("/auth/vf_entra")
    expect(rendered).not_to include("/login/omniauth/")
  end
end
