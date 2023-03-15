class RemovePermalinkFromSpreeProducts < ActiveRecord::Migration[6.1]
  def change
    remove_column :spree_products, :permalink, :string, limit: 255
  end
end
