# frozen_string_literal: true

require_relative "../spec_helper"

RSpec.describe DfcProductTypeFactory do
  describe ".for" do
    it "assigns a top level product type" do
      expect(described_class.for(dfc_id("drink")))
        .to eq DfcLoader.connector.PRODUCT_TYPES.DRINK
    end

    it "assigns a second level product type" do
      expect(described_class.for(dfc_id("soft-drink")))
        .to eq DfcLoader.connector.PRODUCT_TYPES.DRINK.SOFT_DRINK
    end

    it "assigns a leaf level product type" do
      expect(described_class.for(dfc_id("lemonade")))
        .to eq DfcLoader.connector.PRODUCT_TYPES.DRINK.SOFT_DRINK.LEMONADE
    end

    it "returns nil for unknown product type" do
      expect(described_class.for("other")).to be_nil
    end
  end

  def dfc_id(name)
    "https://github.com/datafoodconsortium/taxonomies/releases/latest/download/productTypes.rdf##{name}"
  end
end
