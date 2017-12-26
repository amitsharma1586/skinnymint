namespace :orders do
  desc 'upload shipments to auspost api'
  task upload_order_into_auspost: :environment do
    zones = Spree::ShippingMethod.where(['LOWER(admin_name) like ?', '%auspost%']).map(&:zones).flatten
    if zones.present?
      orders = Spree::Order.joins(ship_address: [{ country: :zones }]).where(['spree_zones.id in (?) and DATE(spree_orders.completed_at) >= ?', zones.map(&:id), Settings['order_sync_date']['auspost']]).unfulfilled
      EasypostOrderWorker.perform_async orders.map(&:id).uniq, 'auspost' if orders.present?
    end
  end
end
