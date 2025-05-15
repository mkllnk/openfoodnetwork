# frozen_string_literal: true

require_relative "../swagger_helper"

RSpec.describe "Scopes", swagger_doc: "dfc.yaml" do
  let!(:user) { create(:oidc_user) }
  let!(:enterprise) do
    create(
      :distributor_enterprise,
      id: 10_000, owner: user, name: "Fred's Farm",
    )
  end

  before { login_as user }

  path "/api/dfc/enterprises/{enterprise_id}/scopes/{id}" do
    parameter name: :enterprise_id, in: :path, type: :string
    parameter name: :id, in: :path, type: :string

    get "Show scope" do
      produces "application/json"

      response "200", "successful" do
        let(:enterprise_id) { enterprise.id }
        let(:id) { "ReadEnterprise" }
        let!(:permission) {
          DfcPermission.create!(user:, enterprise:, grantee: "Discover Regenerative", scope: id)
        }

        run_test! do
          expect(json_response["@id"]).to eq "http://www.example.com/api/dfc/enterprises/10000/scopes/ReadEnterprise"
          expect(json_response["portals"]).to eq ["Discover Regenerative"]
        end
      end
    end

    post "Create scope" do
      consumes "application/json"
      produces "application/json"

      parameter name: :platform, in: :body, schema: {
        example: {
          portalId: "Discover Regenerative",
        }
      }

      response "201", "successful" do
        let(:enterprise_id) { enterprise.id }
        let(:id) { "ReadEnterprise" }
        let(:platform) do |example|
          example.metadata[:operation][:parameters].first[:schema][:example]
        end

        run_test! do
          permission = DfcPermission.last
          expect(permission.enterprise).to eq enterprise
          expect(permission.user).to eq user
          expect(permission.grantee).to eq "Discover Regenerative"
          expect(permission.scope).to eq "ReadEnterprise"
        end
      end
    end

    delete "Destroy scope" do
      consumes "application/json"
      produces "application/json"

      parameter name: :platform, in: :body, schema: {
        example: {
          portalId: "Discover Regenerative",
        }
      }

      response "200", "successful" do
        let(:enterprise_id) { enterprise.id }
        let(:id) { "ReadEnterprise" }
        let!(:permission) {
          DfcPermission.create!(user:, enterprise:, grantee: "Discover Regenerative", scope: id)
        }
        let(:platform) do |example|
          example.metadata[:operation][:parameters].first[:schema][:example]
        end

        run_test! do
          expect { permission.reload }.to raise_error ActiveRecord::RecordNotFound
        end
      end
    end
  end
end
