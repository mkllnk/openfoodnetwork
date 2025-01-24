# frozen_string_literal: true

class SuppliedProductBuilder < DfcBuilder
  def self.semantic_id(variant)
    urls.enterprise_supplied_product_url(
      enterprise_id: variant.supplier_id,
      id: variant.id,
    )
  end

  def self.supplied_product(variant)
    product_uri = urls.enterprise_url(
      variant.supplier_id,
      spree_product_id: variant.product_id
    )
    technical_product = TechnicalProductBuilder.technical_product(variant.product)

    DfcProvider::SuppliedProduct.new(
      semantic_id(variant),
      name: variant.product_and_full_name,
      description: variant.description,
      productType: DfcProductTypeFactory.for(variant.primary_taxon&.dfc_id),
      quantity: QuantitativeValueBuilder.quantity(variant),
      isVariantOf: [technical_product],
      spree_product_uri: product_uri,
      spree_product_id: variant.product.id,
      image_url: variant.product&.image&.url(:product)
    )
  end
end
