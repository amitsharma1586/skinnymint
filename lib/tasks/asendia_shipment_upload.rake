namespace :orders do
  desc 'upload shipments to asendia api'
  task upload_order_into_asendia: :environment do
    zones = Spree::ShippingMethod.where(['LOWER(admin_name) like ?', '%asendia%']).map(&:zones).flatten
    if zones.present?
      orders = Spree::Order.joins(ship_address: [{ country: :zones }]).where(['spree_zones.id in (?) and DATE(spree_orders.completed_at) >= ?', zones.map(&:id), Settings['order_sync_date']['asendia']]).unfulfilled
      AsendiaShipmentWorker.perform_async orders.map(&:id).uniq if orders.present?
    end
  end
end
