namespace :orders do
  desc 'upload shipments to ninjavan api'
  task upload_order_into_ninjavan: :environment do
    zones = Spree::ShippingMethod.where(['LOWER(admin_name) like ?', '%ninjavan%']).map(&:zones).flatten
    if zones.present?
      orders = Spree::Order.joins(ship_address: [{ country: :zones }]).where(['spree_zones.id in (?) and DATE(spree_orders.completed_at) >= ?', zones.map(&:id), Settings['order_sync_date']['ninjavan']]).unfulfilled
      NinjavanShipmentWorker.perform_async orders.map(&:id).uniq if orders.present?
    end
  end
end
