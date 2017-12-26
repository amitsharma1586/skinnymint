namespace :orders do
  desc 'upload shipments to ups api'
  task upload_order_into_ups: :environment do
    zones = Spree::ShippingMethod.where(['LOWER(admin_name) like ?', '%ups%']).map(&:zones).flatten
    if zones.present?
      orders = Spree::Order.joins(ship_address: [{ country: :zones }]).where(['spree_zones.id in (?) and DATE(spree_orders.completed_at) >= ?', zones.map(&:id), Settings['order_sync_date']['ups']]).unfulfilled
      EasypostOrderWorker.perform_async orders.map(&:id).uniq, 'ups' if orders.present?
    end
  end
end
