# frozen_string_literal: true

# Represents a single row of the aggregated sales data.
class AffiliateSalesDataRowBuilder < DfcBuilder
  attr_reader :item

  def initialize(row)
    super()
    @item = AffiliateSalesQuery.label_row(row)
  end

  def build_supplier
    DataFoodConsortium::ConnectorV1::Enterprise.new(
      nil,
      localizations: [
        build_address(
          item[:supplier_postcode],
          item[:supplier_country]
        )
      ],
      suppliedProducts: [build_product]
    )
  end

  def build_distributor
    DataFoodConsortium::ConnectorV1::Enterprise.new(
      nil,
      localizations: [
        build_address(
          item[:distributor_postcode],
          item[:distributor_country]
        )
      ]
    )
  end

  def build_product
    DataFoodConsortium::ConnectorV1::SuppliedProduct
      .new(
        nil,
        name: item[:product_name],
        quantity: build_product_quantity
      )
      .tap do |product|
        product.registerSemanticProperty("dfc-b:concernedBy") {
          build_order_line
        }
      end
  end

  def build_order_line
    DataFoodConsortium::ConnectorV1::OrderLine.new(
      nil,
      quantity: build_line_quantity,
      price: build_price,
      order: build_order
    )
  end

  def build_order
    DataFoodConsortium::ConnectorV1::Order.new(
      nil,
      saleSession: build_sale_session
    )
  end

  def build_sale_session
    DataFoodConsortium::ConnectorV1::SaleSession
      .new(
        nil
      )
      .tap do |session|
        session.registerSemanticProperty("dfc-b:objectOf") {
          build_coordination
        }
      end
  end

  def build_coordination
    DfcProvider::Coordination.new(
      nil,
      coordinator: build_distributor
    )
  end

  def build_product_quantity
    DataFoodConsortium::ConnectorV1::QuantitativeValue.new(
      unit: QuantitativeValueBuilder.unit(item[:unit_type]),
      value: item[:units]&.to_f
    )
  end

  def build_line_quantity
    DataFoodConsortium::ConnectorV1::QuantitativeValue.new(
      unit: DfcLoader.connector.MEASURES.PIECE(),
      value: item[:quantity_sold]&.to_f
    )
  end

  def build_price
    DataFoodConsortium::ConnectorV1::QuantitativeValue.new(
      value: item[:price]&.to_f
    )
  end

  def build_address(postcode, country)
    DataFoodConsortium::ConnectorV1::Address.new(
      nil,
      country:,
      postalCode: postcode
    )
  end
end
