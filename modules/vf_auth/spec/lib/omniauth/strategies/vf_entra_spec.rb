# frozen_string_literal: true

require "spec_helper"
require "omniauth/strategies/vf_entra"

RSpec.describe OmniAuth::Strategies::VfEntra do
  subject(:strategy) { described_class.new({}) }

  let(:tenant_id) { "11111111-1111-1111-1111-111111111111" }
  let(:object_id) { "22222222-2222-2222-2222-222222222222" }
  let(:claims) do
    {
      "tid" => tenant_id,
      "oid" => object_id,
      "preferred_username" => "jeffrey@valuefusion.com",
      "email" => "jeffrey@valuefusion.com",
      "given_name" => "Jeffrey",
      "family_name" => "Example",
      "name" => "Jeffrey Example"
    }
  end

  around do |example|
    previous = {
      "VF_ENTRA_TENANT_ID" => ENV["VF_ENTRA_TENANT_ID"],
      "VF_ENTRA_CLIENT_ID" => ENV["VF_ENTRA_CLIENT_ID"],
      "VF_ENTRA_CLIENT_SECRET" => ENV["VF_ENTRA_CLIENT_SECRET"]
    }
    ENV["VF_ENTRA_TENANT_ID"] = tenant_id
    ENV["VF_ENTRA_CLIENT_ID"] = "client"
    ENV["VF_ENTRA_CLIENT_SECRET"] = "secret"
    example.run
  ensure
    previous.each { |k, v| v.nil? ? ENV.delete(k) : ENV[k] = v }
  end

  before do
    token = instance_double(OpenIDConnect::ResponseObject::IdToken, raw_attributes: claims)
    allow(strategy).to receive(:id_token).and_return(token)
  end

  it "uses vf_entra as the provider name" do
    expect(strategy.options.name).to eq("vf_entra")
  end

  it "builds a durable uid from tid and oid" do
    expect(strategy.uid).to eq("#{tenant_id}:#{object_id}")
  end

  it "maps profile attributes without treating email as identity" do
    expect(strategy.info[:email]).to eq("jeffrey@valuefusion.com")
    expect(strategy.info[:login]).to eq("jeffrey@valuefusion.com")
    expect(strategy.info[:first_name]).to eq("Jeffrey")
    expect(strategy.info[:last_name]).to eq("Example")
    expect(strategy.info[:uid]).to eq("#{tenant_id}:#{object_id}")
  end

  it "fails closed when tid is missing" do
    claims.delete("tid")
    expect { strategy.uid }.to raise_error(OmniAuth::Strategies::VfEntra::MissingIdentityError, /tid/)
  end

  it "fails closed when oid is missing" do
    claims.delete("oid")
    expect { strategy.uid }.to raise_error(OmniAuth::Strategies::VfEntra::MissingIdentityError, /oid/)
  end

  it "fails closed when tid does not match the configured tenant" do
    claims["tid"] = "99999999-9999-9999-9999-999999999999"
    expect { strategy.uid }.to raise_error(OmniAuth::Strategies::VfEntra::TenantMismatchError)
  end
end
