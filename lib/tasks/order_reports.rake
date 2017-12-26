namespace :order_reports do
  desc 'Add orders sales data per country'
  task add_date_orders: :environment do
    order_data = {}
    first_order = Spree::Order.first
    last_order = Spree::Order.last
    start_date = first_order.created_at.strftime('%Y-%m-%d')
    end_date = last_order.created_at.strftime('%Y-%m-%d')
    # start_date = Date.parse(ENV['start_date'])
    # end_date = Date.Today
    orders = Spree::Order.select(:currency, :total, :ship_address_id, :completed_at).where(completed_at: start_date..end_date)
    orders.each do |o|
      next if o.ship_address.nil?
      key = "Country:#{o.completed_at.strftime('%Y-%m-%d')}:#{o.ship_address.country.iso}:#{o.currency}"
      if order_data[key]
        order_data[key].push(o.display_total.money)
      else
        order_data[key] = [o.display_total.money]
      end
    end
    order_data.each do |key, value|
      country_name = Spree::Country.find_by_iso(key.split(':')[2]).name
      sum = value.sum
      usd_sum = sum.exchange_to(:usd)
      REDIS.set key, "#{sum}:#{usd_sum}:#{value.count}:#{country_name}"
    end
  end

  task add_date_orders_for_today: :environment do
    order_data = {}
    start_date = Date.yesterday
    end_date = Date.tomorrow
    orders = Spree::Order.select(:currency, :total, :ship_address_id, :completed_at).where(completed_at: start_date.beginning_of_day..end_date.end_of_day)
    orders.each do |o|
      next if o.ship_address.nil?
      key = "Country:#{o.completed_at.strftime('%Y-%m-%d')}:#{o.ship_address.country.iso}:#{o.currency}"
      if order_data[key]
        order_data[key].push(o.display_total.money)
      else
        order_data[key] = [o.display_total.money]
      end
    end
    order_data.each do |key, value|
      country_name = Spree::Country.find_by_iso(key.split(':')[2]).name
      sum = value.sum
      usd_sum = sum.exchange_to(:usd)
      REDIS.set key, "#{sum}:#{usd_sum}:#{value.count}:#{country_name}"
    end
  end

  desc 'Add orders sku data per country'
  task add_date_sku: :environment do
    order_data = {}
    first_order = Spree::Order.first
    last_order = Spree::Order.last
    start_date = first_order.created_at.strftime('%Y-%m-%d')
    end_date = last_order.created_at.strftime('%Y-%m-%d')
    orders = Spree::Order.includes(line_items: :variant).select(:id, :ship_address_id, :completed_at).where(completed_at: start_date..end_date)
    variants = Hash.new { |hash, key| hash[key] = Spree::Variant.unscoped.find_by_id(key).sku }
    orders.each do |o|
      next if o.ship_address.nil?
      o.line_items.each do |item|
        sku = begin
                item.product.name
              rescue
                variants[item.variant_id]
              end
        key = "SKU:#{o.completed_at.strftime('%Y-%m-%d')}:#{o.ship_address.country.iso}:#{sku}"
        order_data[key] = item.quantity + (order_data[key] || 0)
      end
    end
    order_data.each do |key, value|
      country_name = Spree::Country.find_by_iso(key.split(':')[2]).name
      REDIS.set key, "#{value}:#{country_name}"
    end
  end

  task add_date_sku_for_today: :environment do
    order_data = {}
    start_date = Date.yesterday
    end_date = Date.tomorrow
    orders = Spree::Order.includes(line_items: :variant).select(:id, :ship_address_id, :completed_at).where(completed_at: start_date.beginning_of_day..end_date.end_of_day)
    variants = Hash.new { |hash, key| hash[key] = Spree::Variant.unscoped.find_by_id(key).sku }
    orders.each do |order|
      next if order.ship_address.nil?
      order.line_items.each do |item|
        sku = begin
                item.product.name
              rescue
                variants[item.variant_id]
              end
        key = "SKU:#{order.completed_at.strftime('%Y-%m-%d')}:#{order.ship_address.country.iso}:#{sku}"
        order_data[key] = item.quantity + (order_data[key] || 0)
      end
    end
    order_data.each do |key, value|
      country_name = Spree::Country.find_by_iso(key.split(':')[2]).name
      REDIS.set key, "#{value}:#{country_name}"
    end
  end

  desc 'Add orders sku name data per country'
  task add_date_sku_name: :environment do
    order_data = {}
    first_order = Spree::Order.first
    last_order = Spree::Order.last
    start_date = first_order.created_at.strftime('%Y-%m-%d')
    end_date = last_order.created_at.strftime('%Y-%m-%d')
    orders = Spree::Order.includes(line_items: :variant).select(:id, :ship_address_id, :completed_at).where(completed_at: start_date..end_date)
    variants = Hash.new { |hash, key| hash[key] = Spree::Variant.unscoped.find_by_id(key).sku }
    orders.each do |o|
      next if o.ship_address.nil?
      o.line_items.each do |item|
        sku_name = begin
                item.variant.sku
              rescue
                variants[item.variant_id]
              end
        key = "SKUNAME:#{o.completed_at.strftime('%Y-%m-%d')}:#{o.ship_address.country.iso}:#{sku_name}"
        order_data[key] = item.quantity + (order_data[key] || 0)
      end
    end
    order_data.each do |key, value|
      country_name = Spree::Country.find_by_iso(key.split(':')[2]).name
      REDIS.set key, "#{value}:#{country_name}"
    end
  end

  task add_date_sku_name_for_today: :environment do
    order_data = {}
    start_date = Date.yesterday
    end_date = Date.tomorrow
    orders = Spree::Order.includes(line_items: :variant).select(:id, :ship_address_id, :completed_at).where(completed_at: start_date.beginning_of_day..end_date.end_of_day)
    variants = Hash.new { |hash, key| hash[key] = Spree::Variant.unscoped.find_by_id(key).sku }
    orders.each do |order|
      next if order.ship_address.nil?
      order.line_items.each do |item|
        sku_name = begin
                item.variant.sku
              rescue
                variants[item.variant_id]
              end
        key = "SKUNAME:#{order.completed_at.strftime('%Y-%m-%d')}:#{order.ship_address.country.iso}:#{sku_name}"
        order_data[key] = item.quantity + (order_data[key] || 0)
      end
    end
    order_data.each do |key, value|
      country_name = Spree::Country.find_by_iso(key.split(':')[2]).name
      REDIS.set key, "#{value}:#{country_name}"
    end
  end
end
