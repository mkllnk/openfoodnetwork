# frozen_string_literal: true

class OrderBuilder < DfcBuilder
  def self.new_order(ofn_order)
    id = nil # a new order to be created somewhere else

    DataFoodConsortium::Connector::Order.new(
      id,
      client: urls.enterprise_url(ofn_order.distributor_id),
      # TODO: FulfillementState: held
    )
  end
end
