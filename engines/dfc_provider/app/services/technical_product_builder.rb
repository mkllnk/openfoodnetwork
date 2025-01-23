# frozen_string_literal: true

class TechnicalProductBuilder < DfcBuilder
  def self.technical_product(product)
    id = urls.enterprise_technical_product_url(
      enterprise_id: product.variants.first.supplier_id,
      id: product.id,
    )
    variants = product.variants.map do |spree_variant|
      SuppliedProductBuilder.semantic_id(spree_variant)
    end

    DataFoodConsortium::Connector::TechnicalProduct.new(
      id, variants:,
    )
  end
end
