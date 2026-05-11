# frozen_string_literal: true

RSpec.describe SearchOrders do
  let!(:distributor) { create(:distributor_enterprise) }
  let!(:order1) { create(:order_with_line_items, distributor:, line_items_count: 3) }
  let!(:order2) { create(:order_with_line_items, distributor:, line_items_count: 2) }
  let!(:order3) { create(:order_with_line_items, distributor:, line_items_count: 1) }
  let!(:order_empty) { create(:order, distributor:) }
  let!(:order_empty_but_complete) { create(:order, distributor:, state: :complete) }
  let!(:order_empty_but_canceled) { create(:order, distributor:, state: :canceled) }

  let(:enterprise_user) { distributor.owner }

  describe "#orders" do
    subject(:service) { described_class.new(params, enterprise_user) }
    let(:params) { {} }

    it "returns orders" do
      expect(service.orders.count).to(eq(5))
      service.orders.each do |order|
        expect(order.id).not_to(eq(order_empty.id))
      end
    end

    context("when filtering by payment state") do
      let(:params) { {q: {payment_state_in: ["balance_due"]}} }

      it "returns filtered oredrs" do
        create(:completed_order_with_totals, distributor:, payment_state: "balance_due")
        create(:completed_order_with_totals, distributor:, payment_state: "balance_due")

        expect(service.orders.count).to(eq(2))
      end
    end
  end
end
