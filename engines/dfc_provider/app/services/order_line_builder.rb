# frozen_string_literal: true

class OrderLineBuilder < DfcBuilder
  def self.build(offer, quantity)
    DataFoodConsortium::ConnectorV1::OrderLine.new(
      nil,
      offer:,
      quantity:
    )
  end
end
