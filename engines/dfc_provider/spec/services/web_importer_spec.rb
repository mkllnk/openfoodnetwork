# frozen_string_literal: true

require_relative "../spec_helper"

describe WebImporter do
  subject(:importer) { described_class.new(user) }
  let(:user) { build(:oidc_user) }
  let(:product) do
    DataFoodConsortium::Connector::SuppliedProduct.new(
      "https://example.net/tomato",
      name: "Tomato",
    )
  end
  let(:product_detail) do
    DataFoodConsortium::Connector::SuppliedProduct.new(
      "https://example.net/tomato",
      name: nil,
      description: "Awesome tomato",
      totalTheoreticalStock: 3,
    )
  end

  it "imports a single object" do
    stub_dfc("https://example.net/tomato", product)

    result = importer.import("https://example.net/tomato")

    expect(result.semanticId).to eq "https://example.net/tomato"
    expect(result.name).to eq "Tomato"
  end

  it "imports progressively" do
    stub_dfc("https://example.net/tomato", product)
    stub_dfc("https://example.net/tomato_detail", product_detail)

    result = importer.import("https://example.net/tomato")
    importer.import("https://example.net/tomato_detail")

    expect(result.semanticId).to eq "https://example.net/tomato"
    expect(result.name).to eq "Tomato"
    expect(result.description).to eq "Awesome tomato"
  end

  def stub_dfc(url, *args)
    json = DfcLoader.connector.export(*args)
    stub_request(:get, url).to_return(status: 200, body: json)
  end
end
