# frozen_string_literal: true

# Searches for the best offer for a given product.
#
# A product may be offered cheaper within a wholesale product. So we go through
# the catalog, resolve transformation flows and try to find the cheapest offer.
class OfferBroker
  # The current version of the DFC Connector doesn't support all needed
  # relationships yet. We need to find objects in the graph ourselves.
  class ProductGraph
    def initialize(catalog, product_id)
      @classes = catalog.group_by { |i| i.class.name.demodulize }
      @product_id = product_id
    end

    def consumption_flow
      @consumption_flow ||= @classes["PlannedConsumptionFlow"].find { |i|
        i.product == @product_id
      }
    end

    def production_flow
      @production_flow ||= @classes["PlannedProductionFlow"].find { |i|
        i.semanticId == transformation.productionFlow
      }
    end

    def wholesale_offer
      product = @classes["SuppliedProduct"].find { |i|
        i.semanticId == production_flow.product
      }
      item = @classes["CatalogItem"].find { |i|
        i.semanticId.start_with?(product.semanticId)
      }
      item.offers.first
    end

    private

    def transformation
      @classes["PlannedTransformation"].find { |i|
        i.consumptionFlow == consumption_flow.semanticId
      }
    end
  end

  # We focus on the FDC (Shopify) API for now and ignore all other cases.
  # The catalog link needs to be hard-coded for now because we don't have a
  # good discovery mechanism yet. The DFC is working on it.
  CATALOG_LINK = "https://food-data-collaboration-produc-fe870152f634.herokuapp.com/fdc/products?shop=test-hodmedod.myshopify.com"

  def initialize(user)
    @user = user
  end

  # Returns a DFC Order Line of a wholesale product.
  #
  # Given a product (variant) and a quantity, we find a wholesale version of
  # that product and return a line item with the adjusted quantity for that.
  # For example, if we are looking for six cans of beans, we may find a slab
  # that contains 12 cans of beans. The resulting line item is for 0.5 slabs.
  def best_offer_order_line(variant, quantity)
    link = variant.semantic_links[0]

    # Ignore products that are not linked to the semantic web.
    return unless link

    # I expected the product link to provide offers for the product but I
    # wasn't able to get any data out. So let's search the whole catalog.
    catalog = importer.import(CATALOG_LINK, "products")

    graph = ProductGraph.new(catalog, link.semantic_id)

    adjusted_quantity = quantity *
                        graph.production_flow.quantity.value.to_f /
                        graph.consumption_flow.quantity.value.to_f

    OrderLineBuilder.build(graph.wholesale_offer, adjusted_quantity)
  end

  private

  def importer
    @importer ||= FdcWebImporter.new(@user)
  end
end
