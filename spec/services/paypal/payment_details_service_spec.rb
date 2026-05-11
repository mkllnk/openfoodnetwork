# frozen_string_literal: true

RSpec.describe Paypal::PaymentDetailsService do
  subject { described_class.new(order:) }
  let(:order) { create(:order_with_totals_and_distribution, shipping_fee: 0.00) }
  let(:payment) {
    create(
      :payment,
      state: "checkout",
      order:,
      amount: payment_amount,
      payment_method: paypal_payment_method
    )
  }
  let(:payment_amount) { order.total }
  let(:paypal_payment_method) { create(:paypal_payment_method, distributors: [order.distributor]) }

  before do
    order.update_order!
  end

  it "creates a payment details hash" do
    order.payments << payment

    payment_hash = {
      OrderTotal: {
        currencyID: "AUD",
        value: 10.00
      },
      ItemTotal: {
        currencyID: "AUD",
        value: 10.00
      },
      ShippingTotal: {
        currencyID: "AUD",
        value: 0.00
      },
      TaxTotal: {
        currencyID: "AUD",
        value: 0.00
      },
      ShipToAddress: {},
      PaymentDetailsItem: Array,
      ShippingMethod: "Shipping Method",
      PaymentAction: "Sale"
    }

    expect(subject.call).to(match(payment_hash))
  end

  context("with no pending paypal payment") do
    let(:other_payment) {
      create(:payment, state: "checkout", order:, amount: payment_amount)
    }

    it "returns an empty hash" do
      order.payments << other_payment

      expect(subject.call).to(match({}))
    end
  end

  context("with no line items") do
    let(:order) { create(:order, distributor: create(:distributor_enterprise)) }

    it "only includes the order total" do
      order.update(total: 10.00)
      order.payments << payment

      payment_hash = {
        OrderTotal: {
          currencyID: "AUD",
          value: 10.00
        }
      }

      expect(subject.call).to(match(payment_hash))
    end
  end

  context("with shipping fees") do
    let(:order) { create(:order_with_totals_and_distribution, shipping_fee: 3.00) }

    it "includes shipping fees" do
      order.payments << payment

      payment_hash = {
        OrderTotal: {
          currencyID: "AUD",
          value: 13.00
        },
        ItemTotal: {
          currencyID: "AUD",
          value: 10.00
        },
        ShippingTotal: {
          currencyID: "AUD",
          value: 3.00
        },
        TaxTotal: {
          currencyID: "AUD",
          value: 0.00
        },
        ShipToAddress: {},
        PaymentDetailsItem: Array,
        ShippingMethod: "Shipping Method",
        PaymentAction: "Sale"
      }

      expect(subject.call).to(match(payment_hash))
    end
  end

  context("with taxes") do
    # "order_with_taxes" will create one taxed line item, we set line_item_count to 0 to not create
    # extra line items we don't really care about
    let(:order) {
      create(
        :order_with_taxes,
        line_items_count: 0,
        product_price: 20,
        tax_rate_amount: 0.10,
        tax_rate_name: "Tax 1",
        included_in_price: false
      )
        .tap(&:create_tax_charge!)
    }

    it "includes taxes" do
      order.payments << payment

      payment_hash = {
        OrderTotal: {
          currencyID: "AUD",
          value: 22.00
        },
        ItemTotal: {
          currencyID: "AUD",
          value: 20.00
        },
        ShippingTotal: {
          currencyID: "AUD",
          value: 0.00
        },
        TaxTotal: {
          currencyID: "AUD",
          value: 2.00
        },
        ShipToAddress: {},
        PaymentDetailsItem: Array,
        ShippingMethod: "Shipping Method",
        PaymentAction: "Sale"
      }

      expect(subject.call).to(match(payment_hash))
    end
  end

  context("with customer credit") do
    let(:payment_amount) { 4.00 }

    it "includes a discount" do
      customer_credit = create(
        :payment,
        state: "checkout",
        order:,
        amount: 6.00,
        payment_method: Spree::PaymentMethod.customer_credit
      )
      order.payments << customer_credit
      order.payments << payment

      payment_hash = {
        OrderTotal: {
          currencyID: "AUD",
          value: 4.00
        },
        ItemTotal: {
          currencyID: "AUD",
          value: 10.00
        },
        ShippingTotal: {
          currencyID: "AUD",
          value: 0.00
        },
        TaxTotal: {
          currencyID: "AUD",
          value: 0.00
        },
        ShippingDiscount: {
          currencyID: "AUD",
          value: -6.00
        },
        ShipToAddress: {},
        PaymentDetailsItem: Array,
        ShippingMethod: "Shipping Method",
        PaymentAction: "Sale"
      }

      expect(subject.call).to(match(payment_hash))
    end
  end

  context("with address required") do
    subject { described_class.new(order:, address_required: true) }

    it "includes the ship address" do
      order.payments << payment

      address_hash = {
        Name: "John Doe",
        Street1: "10 Lovely Street",
        Street2: "Northwest",
        CityName: "Herndon",
        Phone: "123-456-7890",
        StateOrProvince: "Vic",
        Country: "AU",
        PostalCode: "20170"
      }

      payment_hash = {
        OrderTotal: {
          currencyID: "AUD",
          value: 10.00
        },
        ItemTotal: {
          currencyID: "AUD",
          value: 10.00
        },
        ShippingTotal: {
          currencyID: "AUD",
          value: 0.00
        },
        TaxTotal: {
          currencyID: "AUD",
          value: 0.00
        },
        ShipToAddress: address_hash,
        PaymentDetailsItem: Array,
        ShippingMethod: "Shipping Method",
        PaymentAction: "Sale"
      }

      expect(subject.call).to(match(payment_hash))
    end
  end
end
