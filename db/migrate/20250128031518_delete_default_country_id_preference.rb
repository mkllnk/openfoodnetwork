# frozen_string_literal: true

class DeleteDefaultCountryIdPreference < ActiveRecord::Migration[7.0]
  def up
    execute(
      <<~SQL
        DELETE FROM spree_preferences
        WHERE key = '/spree/app_configuration/default_country_id '
      SQL
        .squish
    )
  end
end
