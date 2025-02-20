# frozen_string_literal: true

module DfcProvider
  class OrdersController < DfcProvider::ApplicationController
    before_action :check_enterprise

    # List draft orders you placed.
    def index
      orders = []
      render json: DfcIo.export(*orders)
    end
  end
end
