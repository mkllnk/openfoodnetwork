# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AmendBackorderJob do
  let(:order) { create(:completed_order_with_totals) }
  let(:distributor) { order.distributor }
  let(:beans) { beans_item.variant }
  let(:beans_item) { order.line_items.first }
  let(:chia_seed) { chia_item.variant }
  let(:chia_item) { order.line_items.second }
  let(:user) { order.distributor.owner }
  let(:product_link) {
    "https://env-0105831.jcloud-ver-jpe.ik-server.com/api/dfc/Enterprises/test-hodmedod/SuppliedProducts/44519466467635"
  }
  let(:chia_seed_wholesale_link) {
    "https://env-0105831.jcloud-ver-jpe.ik-server.com/api/dfc/Enterprises/test-hodmedod/SuppliedProducts/44519468433715"
  }

  before do
    user.oidc_account = build(:testdfc_account)

      beans.semantic_links << SemanticLink.new(
        semantic_id: product_link
      )
      chia_seed.semantic_links << SemanticLink.new(
        semantic_id: chia_seed_wholesale_link
      )
      order.order_cycle = create(
        :simple_order_cycle,
        distributors: [distributor],
        variants: order.variants,
      )
      order.save!
    end

  describe "#amend_backorder" do
    it "updates an order", vcr: true do
      beans.on_demand = true
      beans_item.update!(quantity: 6)
      beans.on_hand = -3

      chia_item.update!(quantity: 5)
      chia_seed.on_demand = false
      chia_seed.on_hand = 7

      # Record the placed backorder:
      backorder = nil
      allow_any_instance_of(FdcBackorderer).to receive(:send_order)
        .and_wrap_original do |original_method, *args, &_block|
        backorder = args[0]
        original_method.call(*args)
      end

      BackorderJob.new.place_backorder(order)

    # Give the Shopify app time to process and place the order.
    # That process seems to be async.
    sleep 10 if VCR.current_cassette.recording?

      # We ordered a case of 12 cans: -3 + 12 = 9
      expect(beans.on_hand).to eq 9

      # Stock controlled items don't change stock in backorder:
      expect(chia_seed.on_hand).to eq 7

      expect(backorder.lines[0].quantity).to eq 1 # beans
      expect(backorder.lines[1].quantity).to eq 5 # chia

      # Without any change, the backorder shouldn't get changed either:
      allow_any_instance_of(FdcBackorderer).to receive(:send_order)
        .and_wrap_original do |original_method, *args, &_block|
        backorder = args[0]
        original_method.call(*args)
      end
      subject.amend_backorder(order)

      # Same as before:
      expect(beans.on_hand).to eq 9
      expect(chia_seed.on_hand).to eq 7
      expect(backorder.lines[0].quantity).to eq 1 # beans
      expect(backorder.lines[1].quantity).to eq 5 # chia

      # We cancel the only order and that should reduce the order lines to 0.
      order.cancel!
      #expect { order.cancel! }
      #  .to change { chia_seed.reload.on_hand }
      #expect(beans.on_hand).to eq 15
      #expect(chia_seed.on_hand).to eq 12
      allow_any_instance_of(FdcBackorderer).to receive(:send_order)
        .and_wrap_original do |original_method, *args, &_block|
        backorder = args[0]
        original_method.call(*args)
      end
      subject.amend_backorder(order)
     # expect(backorder.lines[0].quantity).to eq 0 # beans
      expect(backorder.lines[1].quantity).to eq 0 # chia

      # Clean up after ourselves:
      perform_enqueued_jobs(only: CompleteBackorderJob)
    end
  end
end
