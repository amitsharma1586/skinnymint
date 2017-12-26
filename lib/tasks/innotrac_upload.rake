namespace :orders do
  desc 'Upload order into innotrac'
  task upload_order_into_innotrac: :environment do
    zones = Spree::ShippingMethod.where(['LOWER(admin_name) like ?', '%innotrac%']).map(&:zones).flatten
    if zones.present?
      country_ids = zones.map(&:country_ids).flatten.uniq
      orders = Spree::Order.joins(ship_address: :country).where(['spree_countries.id in (?)', country_ids]).unfulfilled
      InnotracOrderWorker.perform_async orders.map(&:id).uniq if orders.present?
    end
  end
end
