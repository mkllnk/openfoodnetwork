# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BackorderJob do
  let(:order) { create(:completed_order_with_totals) }

  describe ".check_stock" do
    it "ignores products without semantic link" do
      BackorderJob.check_stock(order)
    end
  end

  describe ".best_offer" do
    # This is a copy from our API docs.
    # But once available, we can record a real response.
    let(:catalog_json) {
      <<~JSON
        {
          "@context": "https://www.datafoodconsortium.org",
          "@graph": [
            {
              "@id": "http://test.host/api/dfc/persons/12345",
              "@type": "dfc-b:Person",
              "dfc-b:affiliates": "http://test.host/api/dfc/enterprises/10000"
            },
            {
              "@id": "http://test.host/api/dfc/enterprises/10000",
              "@type": "dfc-b:Enterprise",
              "dfc-b:hasAddress": "http://test.host/api/dfc/addresses/40000",
              "dfc-b:name": "Fred's Farm",
              "dfc-b:hasDescription": "Beautiful",
              "dfc-b:manages": "http://test.host/api/dfc/enterprises/10000/catalog_items/10001",
              "dfc-b:supplies": "http://test.host/api/dfc/enterprises/10000/supplied_products/10001",
              "ofn:long_description": "<p>Hello, world!</p><p>This is a paragraph.</p>"
            },
            {
              "@id": "http://test.host/api/dfc/enterprises/10000/catalog_items/10001",
              "@type": "dfc-b:CatalogItem",
              "dfc-b:references": "http://test.host/api/dfc/enterprises/10000/supplied_products/10001",
              "dfc-b:sku": "AR",
              "dfc-b:stockLimitation": 0,
              "dfc-b:offeredThrough": "http://test.host/api/dfc/enterprises/10000/offers/10001"
            },
            {
              "@id": "http://test.host/api/dfc/enterprises/10000/supplied_products/10001",
              "@type": "dfc-b:SuppliedProduct",
              "dfc-b:name": "Apple - 1g",
              "dfc-b:description": "Red",
              "dfc-b:hasType": "dfc-pt:non-local-vegetable",
              "dfc-b:hasQuantity": {
                "@type": "dfc-b:QuantitativeValue",
                "dfc-b:hasUnit": "dfc-m:Gram",
                "dfc-b:value": 1
              },
              "dfc-b:alcoholPercentage": 0,
              "dfc-b:lifetime": "",
              "dfc-b:usageOrStorageCondition": "",
              "dfc-b:totalTheoreticalStock": 0,
              "ofn:spree_product_id": 90000,
              "ofn:spree_product_uri": "http://test.host/api/dfc/enterprises/10000?spree_product_id=90000"
            },
            {
              "@id": "http://test.host/api/dfc/enterprises/10000/offers/10001",
              "@type": "dfc-b:Offer",
              "dfc-b:hasPrice": 19.99,
              "dfc-b:stockLimitation": 0
            }
          ]
        }
      JSON
    }

    it "finds a linked offer", vcr: true do
      dfc_user = build(:dfc_user)
      variant = order.line_items[0].variant

      variant.semantic_links << SemanticLink.new(
        semantic_id: "https://food-data-collaboration-produc-fe870152f634.herokuapp.com/product/44519466467635?shop=test-hodmedod.myshopify.com"
      )

      offer = BackorderJob.best_offer(dfc_user, variant)

      expect(offer.semanticId).to eq "http://test.host/api/dfc/enterprises/10000/offers/10001"
    end
  end
end
