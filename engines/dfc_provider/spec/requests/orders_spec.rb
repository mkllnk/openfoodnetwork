# frozen_string_literal: true

require_relative "../swagger_helper"

RSpec.describe "Orders", swagger_doc: "dfc.yaml" do
  let(:user) { create(:oidc_user) }
  let(:enterprise) do
    create(
      :enterprise,
      id: 10_000, owner: user,
    )
  end

  before { login_as user }

  path "/api/dfc/enterprises/{enterprise_id}/orders" do
    get "List orders" do
      parameter name: :enterprise_id, in: :path, type: :string
      produces "application/json"

      response "200", "successful" do
        let(:enterprise_id) { enterprise.id }

        run_test! do
          # TODO: Enable Connector to export empty graph.
          # expect(json_response).to include(
          #   "@id" => "http://test.host/api/dfc/enterprises/10000/orders",
          # )
        end
      end
    end
  end
end
