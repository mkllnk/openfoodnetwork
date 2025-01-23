# frozen_string_literal: true

# Show Spree::Product as TechnicalProduct with variants.
module DfcProvider
  class TechnicalProductsController < DfcProvider::ApplicationController
    before_action :check_enterprise

    def show
      spree_product = current_enterprise.supplied_products.find(params[:id])
      product = TechnicalProductBuilder.technical_product(spree_product)
      render json: DfcIo.export(product)
    end
  end
end
