# frozen_string_literal: true

class BackorderJob < ApplicationJob
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
    api.call("https://example.net/orders", json)

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

    importer = FdcWebImporter.new(user)
    catalog = importer.import(link.semantic_id)

    # WIP: possibly add more to the catalog, resolving more URIs
    catalog.find do |item|
      # Might there be multiple?
      item.is_a?(DataFoodConsortium::Connector::Offer)
    end
  end

  def perform(*args)
    # The ordering logic will live here later.
  end
end
