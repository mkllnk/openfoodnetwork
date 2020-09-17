#!/usr/bin/env ruby

# Create CSV files for each producer in recently closed order cycles.
#
# It's similar data to the email sent to producers but as a CSV file.
#
# Use like this:
#
#   bundle exec rails runner script/order_cycle_producer_csv.rb

def export_csv_files_for_recently_closed_order_cycles
  recently_closed_order_cycles.find_each do |order_cycle|
    export_csv_files(order_cycle)# if csv_files_missing(order_cycle)
  end
end

def csv_files_missing(order_cycle)
  id = order_cycle.id
  Dir.glob("log/csv/order_cycle_#{id}_*.csv").empty?
end

def export_csv_files(order_cycle)
  dir = "log/csv"
  FileUtils.mkdir_p(dir)
  summary = []
  items_by_supplier = line_item_totals(order_cycle).group_by(&:supplier_id)
  items_and_fees_by_supplier = add_fees(order_cycle.id, items_by_supplier)
  items_and_fees_by_supplier.each do |supplier_id, items|
    rows = items.map { |item| attributes_of(item) }
    summary += rows
    export_supplier_file(dir, order_cycle.id, supplier_id, rows)
  end
  export_order_cycle_file(dir, order_cycle.id, summary)
end

def export_supplier_file(dir, order_cycle_id, supplier_id, rows)
  filename = "order_cycle_#{order_cycle_id}_supplier_#{supplier_id}.csv"
  write_csv_file(dir, filename, rows)
end

def export_order_cycle_file(dir, order_cycle_id, rows)
  filename = "order_cycle_#{order_cycle_id}.csv"
  write_csv_file(dir, filename, rows)
end

def write_csv_file(dir, filename, rows)
  return if rows.empty?

  puts "Writing: #{filename}"
  CSV.open("#{dir}/#{filename}", "w") do |csv|
    csv << rows.first.keys
    rows.each { |row| csv << row.values }
  end
end

def attributes_of(item)
  attributes = item.attributes
  attributes["average_cost_per_unit"] = average_cost_per_unit(attributes)
  attributes["unit_name"] = unit_for(attributes)
  attributes
end

def average_cost_per_unit(attributes)
  amount = attributes["amount"].to_f
  units = attributes["total_units"].to_f

  return if amount.nil? || units.zero?

  "%.2f" % (amount / units).round(2)
end

def unit_for(attributes)
  {
    "volume" => {
      "0.001" => "mL",
      "1" => "L",
      "1000" => "kL"
    },
    "weight" => {
      "1" => "g",
      "1000" => "kg",
      "1000000" => "T"
    },
  }.fetch(attributes["variant_unit"], attributes["variant_unit_scale"])
end

def recently_closed_order_cycles
  OrderCycle.closed.where("orders_close_at > ?", 30.day.ago)
end

def line_item_totals(order_cycle)
  line_items(order_cycle).
    joins("LEFT OUTER JOIN spree_tax_categories
           ON spree_tax_categories.id = spree_line_items.tax_category_id").
    joins("LEFT OUTER JOIN spree_adjustments
           ON spree_adjustments.adjustable_id = spree_line_items.id
           AND spree_adjustments.adjustable_type = 'Spree::LineItem'").
    group("
          order_cycle_id,
          supplier_id,
          enterprises.id,
          spree_products.id,
          spree_variants.sku,
          spree_tax_categories.id
    ").
    select("
            order_cycle_id,
            supplier_id,
            enterprises.name AS supplier,
            enterprises.charges_sales_tax,
            spree_products.id AS product_id,
            spree_variants.sku,
            spree_products.name AS product,
            sum(spree_line_items.price * spree_line_items.quantity) AS amount,
            round(sum(spree_line_items.final_weight_volume / coalesce(spree_products.variant_unit_scale, 1))::numeric, 2) AS total_units,
            NULL AS unit_name,
            variant_unit,
            spree_products.variant_unit_scale,
            sum(spree_line_items.price * spree_line_items.quantity) - sum(coalesce(spree_adjustments.included_tax, 0)) AS total_cost_ex_tax,
            coalesce(spree_tax_categories.name, 'None') AS tax_code,
            sum(coalesce(spree_adjustments.included_tax, 0)) AS tax_paid
    ").
    order("spree_products.name")
end

def supplier_fee_totals(order_cycle_id, supplier_id)
  items_of_supplier = line_items(order_cycle_id).where("supplier_id = ?", supplier_id)
  item_ids = items_of_supplier.distinct.select("spree_line_items.id")
  order_ids = items_of_supplier.distinct.select("spree_line_items.order_id")
  Spree::Adjustment.
    joins("INNER JOIN enterprise_fees
           ON spree_adjustments.originator_id = enterprise_fees.id
           AND spree_adjustments.originator_type = 'EnterpriseFee'
           AND enterprise_fees.enterprise_id = #{supplier_id}").
    joins("LEFT OUTER JOIN spree_orders
           ON spree_adjustments.adjustable_id = spree_orders.id
           AND spree_adjustments.adjustable_type = 'Spree::Order'
           AND spree_orders.id in (#{order_ids.to_sql})
          ").
    joins("LEFT OUTER JOIN spree_line_items
           ON spree_adjustments.adjustable_id = spree_line_items.id
           AND spree_adjustments.adjustable_type = 'Spree::LineItem'
           AND spree_line_items.id in (#{item_ids.to_sql})
          ").
    where("spree_orders.id IS NOT NULL OR spree_line_items.id IS NOT NULL").
    group("
          order_cycle_id,
          enterprise_fees.enterprise_id
    ").
    select("
            order_cycle_id,
            enterprise_fees.enterprise_id AS supplier_id,
            NULL AS supplier,
            NULL AS charges_sales_tax,
            NULL AS product_id,
            NULL AS sku,
            'Supplier fee total' AS product,
            sum(coalesce(spree_adjustments.amount, 0)) AS amount,
            NULL AS total_units,
            NULL AS unit_name,
            NULL AS variant_unit,
            NULL AS variant_unit_scale,
            sum(spree_adjustments.amount) - sum(coalesce(spree_adjustments.included_tax, 0)) AS total_cost_ex_tax,
            NULL AS tax_code,
            sum(coalesce(spree_adjustments.included_tax, 0)) AS tax_paid
    ")
end

def add_fees(order_cycle_id, items_by_supplier)
  items_by_supplier.each do |supplier_id, items|
    fees = supplier_fee_totals(order_cycle_id, supplier_id).to_a
    items.append(*fees) if fees.present?
  end
end

def line_items(order_cycle_id)
  Spree::LineItem.
    from_order_cycle(order_cycle_id).
    merge(Spree::Order.by_state('complete')).
    # Using explicit joins to avoid default scopes and consider deleted variants.
    joins("INNER JOIN spree_variants ON spree_variants.id = spree_line_items.variant_id").
    joins("INNER JOIN spree_products ON spree_products.id = spree_variants.product_id").
    joins("INNER JOIN enterprises ON enterprises.id = spree_products.supplier_id")
end

export_csv_files_for_recently_closed_order_cycles
