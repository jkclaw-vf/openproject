# frozen_string_literal: true

require "spec_helper"

RSpec.describe OmniAuthStartController, "vf_entra permission", type: :controller do
  render_views

  let(:tenant_id) { "11111111-1111-1111-1111-111111111111" }

  around do |example|
    keys = %w[VF_ENTRA_TENANT_ID VF_ENTRA_CLIENT_ID VF_ENTRA_CLIENT_SECRET]
    previous = keys.index_with { |k| ENV[k] }
    ENV["VF_ENTRA_TENANT_ID"] = tenant_id
    ENV["VF_ENTRA_CLIENT_ID"] = "client"
    ENV["VF_ENTRA_CLIENT_SECRET"] = "secret"
    example.run
  ensure
    previous.each { |k, v| v.nil? ? ENV.delete(k) : ENV[k] = v }
  end

  before do
    allow(EnterpriseToken).to receive(:allows_to?).and_return(false)
  end

  it "permits vf_entra without Enterprise SSO entitlement" do
    get :show, params: { provider: "vf_entra" }
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("omniauth-direct-login-form")
  end

  it "does not permit arbitrary providers" do
    get :show, params: { provider: "not-a-provider" }
    expect(response).to have_http_status(:not_found)
  end
end
