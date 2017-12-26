# Innotrac worker to handle innotrac shipment
class InnotracWorker
  include Sidekiq::Worker

  def perform(order_ids = [])
    @success_orders = []
    @failed_orders = []
    if order_ids.blank?
      zones = Spree::ShippingMethod.where(['LOWER(admin_name) like ?', '%innotrac%']).map(&:zones).flatten
      if zones.present?
        country_ids = zones.map(&:country_ids).flatten.uniq
        orders = Spree::Order.joins(ship_address: :country).where(['spree_countries.id in (?)', country_ids]).unfulfilled.uniq
      end
    else
      orders = Spree::Order.joins(ship_address: :country).where(id: order_ids).unfulfilled.uniq
    end

    (orders||[]).each do |order|
      unless FulfillmentOrder.exists?(order_number: order.number)
        inno = InnotracOrder.create!(order_number: order.number)
        inno.upload
        if inno.response.try(:downcace) == 'ok'
          order.line_item.each do |line_item|
            @success_orders << ["#{order.number}, #{line_item.sku}, '', #{inno.transaction_number}, #{line_item.quantity}, #{order.completed_at}, #{(order.ship_address.country.try(:name) || '').delete(',')}"]
          end
        else
          @failed_orders << ["#{order.number}, '', #{inno.transaction_number}, #{order.quantity}, #{order.completed_at}, #{(inno.response || '').delete(',')}, #{(order.ship_address.country.try(:name) || '').delete(',')}"]
        end
      end
    end
    send_success_report
    send_failure_report
  end

  # send success order report
  def send_success_report
    return if @success_orders.blank?
    success_orders = ['Order, SKU, Tracking, ParcelId, Quantity, Date, Country'] + @success_orders
    Spree::InnotracMailer.csv(success_orders.join("\n"), 'innotrac', "Sand & Sky : INNOTRAC Shipments Report(#{Time.now.strftime('%d/%m/%Y')})").deliver
  end

  # send failed order report
  def send_failure_report
    return if @failed_orders.blank?
    failed_orders = ['Order, Tracking, ParcelId, Quantity, Date, Error_Message, Country'] + @failed_orders
    Spree::InnotracMailer.csv(failed_orders.join("\n"), 'innotrac', "Sand & Sky : INNOTRAC Failed Shipments Report(#{Time.now.strftime('%d/%m/%Y')})").deliver
  end
end
