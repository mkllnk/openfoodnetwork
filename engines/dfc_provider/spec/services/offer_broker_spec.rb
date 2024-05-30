# frozen_string_literal: true

RSpec.describe OfferBroker, vcr: true do
  let(:subject) { OfferBroker.new(user) }
  let(:user) { build(:dfc_user) }
  let(:variant) { build(:variant, semantic_links: [link]) }
  let(:link) { SemanticLink.new( semantic_id:) }
  let(:semantic_id) {
    "https://food-data-collaboration-produc-fe870152f634.herokuapp.com/product/44519466467635"
  }

  it "finds an offer and adjusts the quantity" do
    item = subject.best_offer_order_line(variant, 6)

    # The found product is a twelve-pack of the original.
    expect(item.offer.semanticId).to eq "https://food-data-collaboration-produc-fe870152f634.herokuapp.com/product/44519466500403/offer"
    expect(item.quantity).to eq 0.5
  end
end
