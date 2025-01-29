# frozen_string_literal: true

require_relative "../spec_helper"

RSpec.describe DfcProductTypeFactory do
  describe ".for" do
    let(:dfc_id) {
      "https://github.com/datafoodconsortium/taxonomies/releases/latest/download/productTypes.rdf#drink"
    }

    it "assigns a top level product type" do
      expect(described_class.for(dfc_id))
        .to eq DfcLoader.connector.PRODUCT_TYPES.DRINK
    end

    context "with second level product type" do
      let(:dfc_id) {
        "https://github.com/datafoodconsortium/taxonomies/releases/latest/download/productTypes.rdf#soft-drink"
      }

      it "assigns a second level product type" do
        expect(described_class.for(dfc_id))
          .to eq DfcLoader.connector.PRODUCT_TYPES.DRINK.SOFT_DRINK
      end
    end

    context "with leaf level product type" do
      let(:dfc_id) {
        "https://github.com/datafoodconsortium/taxonomies/releases/latest/download/productTypes.rdf#lemonade"
      }

      it "assigns a leaf level product type" do
        expect(described_class.for(dfc_id))
          .to eq DfcLoader.connector.PRODUCT_TYPES.DRINK.SOFT_DRINK.LEMONADE
      end
    end

    context "with non existing product type" do
      let(:dfc_id) { "other" }

      it "returns nil" do
        expect(described_class.for(dfc_id)).to be_nil
      end
    end
  end
end
