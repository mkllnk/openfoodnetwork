# frozen_string_literal: true

class AffiliateSalesDataBuilder < DfcBuilder
  class << self
    def person(user, filters = {})
      data = AffiliateSalesQuery.data(user.affiliate_enterprises, **filters)
      suppliers = data.map do |row|
        AffiliateSalesDataRowBuilder.new(row).build_supplier
      end

      DataFoodConsortium::ConnectorV1::Person.new(
        urls.affiliate_sales_data_url,
        affiliatedOrganizations: suppliers
      )
    end
  end
end
