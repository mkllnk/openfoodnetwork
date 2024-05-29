# frozen_string_literal: true

class BackorderJob < ApplicationJob
  FDC_CATALOG_URL = "https://env-0105831.jcloud-ver-jpe.ik-server.com/api/dfc/Enterprises/test-hodmedod/SuppliedProducts"
  FDC_ORDERS_URL = "https://env-0105831.jcloud-ver-jpe.ik-server.com/api/dfc/Enterprises/test-hodmedod/Orders"

  queue_as :default

  def self.check_stock(order)
    variants_needing_stock = order.variants.select do |variant|
      variant.on_hand.negative?
    end

    linked_variants = variants_needing_stock.select do |variant|
      variant.semantic_links.present?
    end

    return if linked_variants.empty?

    # At this point we want to move to the background with perform_later.
    # But while this is in development I'll perform the backordering
    # immediately. It should ease debugging for now.

    backorder = build_order(order)

    linked_variants.each do |variant|
      needed_quantity = -1 * variant.on_hand
      offer = best_offer(order.distributor.owner, variant)
      backorder.lines << build_order_line(offer, needed_quantity)
    end

    json = DfcIo.export(backorder, *backorder.lines)

    api = DfcRequest.new(order.distributor.owner)

    # TODO: delete old order if exists
    # Create order via POST:
    api.call(FDC_ORDERS_URL, json)

    # Once we have transformations and know the quantities in bulk products
    # we will need to increase on_hand by the ordered quantity.
    linked_variants.each do |variant|
      variant.on_hand = 0
    end
  end

  # This needs to find an existing order when the API is available.
  def self.build_order(ofn_order)
    OrderBuilder.new_order(ofn_order)
  end

  def self.build_order_line(offer, quantity)
    OrderLineBuilder.build(offer, quantity)
  end

  def self.best_offer(user, variant)
    link = variant.semantic_links[0]

    return unless link

    importer = WebImporter.new(user)
    catalog = importer.import(FDC_CATALOG_URL)
    product = catalog.find { |item| item.semanticId == link.semantic_id }

    product&.catalogItems&.first&.offers&.first
  end

  def perform(*args)
    # The ordering logic will live here later.
  end
end
