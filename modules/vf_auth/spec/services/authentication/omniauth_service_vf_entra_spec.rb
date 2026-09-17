# frozen_string_literal: true

require "spec_helper"

RSpec.describe Authentication::OmniauthService, "vf_entra linking" do
  let(:controller) { instance_double(ApplicationController, session: {}, request: instance_double(ActionDispatch::Request, env: {})) }
  let(:strategy) { instance_double(OmniAuth::Strategies::VfEntra, name: "vf_entra", respond_to?: false) }
  let(:tenant_id) { "11111111-1111-1111-1111-111111111111" }
  let(:object_id) { "22222222-2222-2222-2222-222222222222" }
  let(:auth_hash) do
    OmniAuth::AuthHash.new(
      provider: "vf_entra",
      uid: "#{tenant_id}:#{object_id}",
      info: {
        email: user.mail,
        login: user.login,
        first_name: user.firstname,
        last_name: user.lastname,
        uid: "#{tenant_id}:#{object_id}"
      }
    )
  end
  let!(:auth_provider) do
    PluginAuthProvider.find_or_create_by!(slug: "vf_entra") do |p|
      p.display_name = "Microsoft"
      p.available = true
      p.creator = User.system
    end
  end
  let!(:user) { create(:user, login: "jeffrey", mail: "jeffrey@valuefusion.com") }

  before do
    allow(Setting).to receive(:oauth_allow_remapping_of_existing_users?).and_return(true)
    allow(Setting::SelfRegistration).to receive_messages(disabled?: true, enabled?: false)
  end

  it "links an existing user by login without creating a duplicate" do
    expect do
      result = described_class.new(strategy:, auth_hash:, controller:).call
      expect(result).to be_success
      expect(result.result.id).to eq(user.id)
    end.not_to change(User, :count)

    link = UserAuthProviderLink.find_by!(principal: user, auth_provider:)
    expect(link.external_id).to eq("#{tenant_id}:#{object_id}")
  end

  it "rejects creating a brand-new uninvited user when self-registration is disabled" do
    unknown = OmniAuth::AuthHash.new(
      provider: "vf_entra",
      uid: "#{tenant_id}:33333333-3333-3333-3333-333333333333",
      info: {
        email: "stranger@valuefusion.com",
        login: "stranger@valuefusion.com",
        first_name: "Stranger",
        last_name: "User",
        uid: "#{tenant_id}:33333333-3333-3333-3333-333333333333"
      }
    )

    result = described_class.new(strategy:, auth_hash: unknown, controller:).call
    expect(result).to be_failure
    expect(User.find_by(login: "stranger@valuefusion.com")).to be_nil
  end
end
