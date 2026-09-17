# frozen_string_literal: true

require "spec_helper"
require "omniauth/strategies/vf_entra"

RSpec.describe OpenProject::VfAuth::Configuration do
  around do |example|
    keys = %w[VF_ENTRA_TENANT_ID VF_ENTRA_CLIENT_ID VF_ENTRA_CLIENT_SECRET VF_ENTRA_ISSUER VF_ENTRA_PROVIDER_NAME]
    previous = keys.index_with { |k| ENV[k] }
    keys.each { |k| ENV.delete(k) }
    example.run
  ensure
    previous.each { |k, v| v.nil? ? ENV.delete(k) : ENV[k] = v }
  end

  describe ".enabled?" do
    it "is false without credentials" do
      expect(described_class).not_to be_enabled
    end

    it "is true when tenant, client id and secret are set" do
      ENV["VF_ENTRA_TENANT_ID"] = "tenant-guid"
      ENV["VF_ENTRA_CLIENT_ID"] = "client-guid"
      ENV["VF_ENTRA_CLIENT_SECRET"] = "secret"
      expect(described_class).to be_enabled
    end
  end

  describe ".issuer" do
    it "defaults to the tenant-specific v2 issuer" do
      ENV["VF_ENTRA_TENANT_ID"] = "tenant-guid"
      expect(described_class.issuer).to eq("https://login.microsoftonline.com/tenant-guid/v2.0")
    end

    it "allows an explicit issuer override" do
      ENV["VF_ENTRA_TENANT_ID"] = "tenant-guid"
      ENV["VF_ENTRA_ISSUER"] = "https://login.microsoftonline.com/tenant-guid/v2.0"
      expect(described_class.issuer).to eq("https://login.microsoftonline.com/tenant-guid/v2.0")
    end
  end

  describe ".to_omniauth_options" do
    before do
      ENV["VF_ENTRA_TENANT_ID"] = "tenant-guid"
      ENV["VF_ENTRA_CLIENT_ID"] = "client-guid"
      ENV["VF_ENTRA_CLIENT_SECRET"] = "secret"
    end

    it "configures discovery, openid scopes, and provider name vf_entra" do
      options = described_class.to_omniauth_options
      expect(options[:name]).to eq("vf_entra")
      expect(options[:discovery]).to be(true)
      expect(options[:scope]).to include(:openid, :profile, :email)
      expect(options[:issuer]).to include("tenant-guid")
      expect(options[:client_options][:identifier]).to eq("client-guid")
      expect(options[:client_options][:secret]).to eq("secret")
    end
  end
end
