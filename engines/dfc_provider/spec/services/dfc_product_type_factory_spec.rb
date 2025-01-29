# frozen_string_literal: true

require_relative "../spec_helper"

RSpec.describe DfcProductTypeFactory do
  let(:drink) {
        DfcLoader.connector.PRODUCT_TYPES.DRINK
  }
  let(:soft_drink) {
    DfcLoader.connector.PRODUCT_TYPES.DRINK.SOFT_DRINK
  }
  let(:lemonade) {
    DfcLoader.connector.PRODUCT_TYPES.DRINK.SOFT_DRINK.LEMONADE
  }

  describe ".for" do
    it "finds a top level product type" do
      expect(described_class.for(dfc_id("drink"))) .to eq drink
    end

    it "finds a second level product type" do
      expect(described_class.for(dfc_id("soft-drink"))) .to eq soft_drink
    end

    it "finds a leaf level product type" do
      expect(described_class.for(dfc_id("lemonade"))) .to eq lemonade
    end

    it "returns nil for unknown product type" do
      expect(described_class.for("other")).to be_nil
    end
  end

  describe ".list_broaders" do
    it "returns an empty array if no type is given" do
      list = described_class.list_broaders(nil)
      expect(list).to eq []
    end

    it "can return an empty list for top concepts" do
      list = described_class.list_broaders(drink)
      expect(list).to eq []
    end

    it "lists the broader concepts of a type" do
      list = described_class.list_broaders(soft_drink)
      expect(list).to eq [drink]
    end

    it "lists all the broader concepts to the top concepts" do
      list = described_class.list_broaders(lemonade)
      expect(list).to eq [soft_drink, drink]
    end
  end

  def dfc_id(name)
    "https://github.com/datafoodconsortium/taxonomies/releases/latest/download/productTypes.rdf##{name}"
  end
end
