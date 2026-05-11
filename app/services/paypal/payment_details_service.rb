# frozen_string_literal: true

module Paypal
  class PaymentDetailsService
    def initialize(order:, address_required: false)
      @order = order
      @address_required = address_required
    end

    # rubocop:disable Metrics/MethodLength
    def call
      items = Paypal::ItemsBuilderService.new(order).call

      item_sum = items.sum { |i| i[:Quantity] * i[:Amount][:value] }
      tax_adjustments_total = order.all_adjustments.tax.additional.sum(:amount)

      last_payment = payment_finder.last_pending_paypal_payment
      return {} if last_payment.nil?

      customer_credit_payment = payment_finder.last_customer_credit

      if item_sum.zero?
        # Paypal does not support no items or a zero dollar ItemTotal
        # This results in the order summary being simply "Current purchase"
        payment_hash = {
          OrderTotal: {
            currencyID: order.currency,
            value: last_payment.amount
          }
        }
        return payment_hash
      end

      payment_hash = {
        OrderTotal: {
          currencyID: order.currency,
          value: last_payment.amount
        },
        ItemTotal: {
          currencyID: order.currency,
          value: item_sum
        },
        ShippingTotal: {
          currencyID: order.currency,
          value: order.ship_total
        },
        TaxTotal: {
          currencyID: order.currency,
          value: tax_adjustments_total
        },
        ShipToAddress: address_options,
        PaymentDetailsItem: items,
        ShippingMethod: "Shipping Method",
        PaymentAction: "Sale"
      }

      if customer_credit_payment.present?
        # We use ShippingDiscount to model customer credit, so in the end :
        # OrderTotal + ShippingDiscount = ItemTotal + ShippingTotal + TaxTotal
        payment_hash[:ShippingDiscount] = {
          currencyID: order.currency,
          value: (-1 * customer_credit_payment.amount)
        }
      end

      payment_hash
    end

    private

    attr_reader :order, :address_required

    def payment_finder
      Orders::FindPaymentService.new(order)
    end

    # rubocop:disable Metrics/CyclomaticComplexity
    def address_options
      return {} unless address_required

      {
        Name: order.bill_address.try(:full_name),
        Street1: order.bill_address&.address1,
        Street2: order.bill_address&.address2,
        CityName: order.bill_address&.city,
        Phone: order.bill_address&.phone,
        StateOrProvince: order.bill_address&.state_text,
        Country: order.bill_address&.country&.iso,
        PostalCode: order.bill_address&.zipcode
      }
    end
  end
end
