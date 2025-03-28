# frozen_string_literal: true

require_relative "../spec_helper"

RSpec.describe DfcLoader do
  it "prepares the DFC Connector to provide DFC object classes for export" do
    tomato = DataFoodConsortium::Connector::SuppliedProduct.new(
      "https://openfoodnetwork.org/tomato",
      name: "Tomato",
      description: "Awesome tomato",
    )

    expect(tomato.name).to eq "Tomato"
    expect(tomato.description).to eq "Awesome tomato"

    json = DfcIo.export(tomato)
    result = JSON.parse(json)

    expect(result.keys).to include(
      *%w(@context @type dfc-b:name dfc-b:description)
    )
    expect(result["dfc-b:name"]).to eq "Tomato"
  end

  it "loads vocabularies" do
    terms = DfcLoader.vocabulary("vocabulary")
    expect(terms.STATES.ORDERSTATE.HELD.semanticId)
      .to eq "https://github.com/datafoodconsortium/taxonomies/releases/latest/download/vocabulary.rdf#Held"
  end
end
