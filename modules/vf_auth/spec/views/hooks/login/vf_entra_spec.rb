# frozen_string_literal: true

require "spec_helper"

RSpec.describe "VF Entra login provider hook", type: :view do
  include OmniauthHelper

  around do |example|
    previous = ENV.to_hash.slice("VF_ENTRA_TENANT_ID", "VF_ENTRA_CLIENT_ID", "VF_ENTRA_CLIENT_SECRET")
    ENV["VF_ENTRA_TENANT_ID"] = "11111111-1111-1111-1111-111111111111"
    ENV["VF_ENTRA_CLIENT_ID"] = "client"
    ENV["VF_ENTRA_CLIENT_SECRET"] = "secret"
    example.run
  ensure
    %w[VF_ENTRA_TENANT_ID VF_ENTRA_CLIENT_ID VF_ENTRA_CLIENT_SECRET].each do |key|
      previous.key?(key) ? ENV[key] = previous[key] : ENV.delete(key)
    end
  end

  it "renders the Microsoft button when configured" do
    render partial: "hooks/login/vf_entra"
    expect(rendered).to include("Continue with Microsoft")
    expect(rendered).to include("/login/omniauth/vf_entra")
  end
end
