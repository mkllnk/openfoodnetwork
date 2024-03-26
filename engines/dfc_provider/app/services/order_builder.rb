# frozen_string_literal: true

class OrderBuilder < DfcBuilder
  def self.new_order(ofn_order)
    id = nil # a new order to be created somewhere else

    DataFoodConsortium::Connector::Order.new(
      id,
      number: ofn_order.number,
      date: ofn_order.completed_at.to_s,
      client: urls.enterprise_url(ofn_order.distributor_id),
      lines: order_lines(ofn_order),
    )
  end

  def self.order_lines(ofn_order)
    ofn_order.line_items.map(&method(:order_line))
  end

  def self.order_line(line_item)
    DataFoodConsortium::Connector::OrderLine.new(
      nil,
      quantity: line_item.quantity,
      offer: nil, # TODO: link to offer on other platform
    )
  end
end
