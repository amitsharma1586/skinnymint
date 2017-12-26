# asendia worker to sync orders on asendia api using background jobs
class AsendiaShipmentWorker
  include Sidekiq::Worker
  include Spree::Shipments::AsendiaApi

  def perform(order_ids = nil)
    zones = Spree::ShippingMethod.where(['LOWER(admin_name) like ?', '%asendia%']).map(&:zones).flatten
    order_ids = order_ids.blank? ? fetch_order_ids(zones) : order_ids
    @success_orders = []
    @failed_orders = []
    orders = Spree::Order.joins({ ship_address: :country }, :variants, :shipments).order('spree_countries.name, spree_variants.sku').where(id: order_ids).where('spree_shipments.tracking is ?', nil)
    orders.to_a.uniq.each do |order|
      begin
        @order = order
        @request, @response = add_order(order.id)
        @response.try(:code) == 200 ? process_order : create_asendia_shipment_record('Failure', 'order shipment not available')
      rescue StandardError => e
        @failed_orders << ["#{order.number}, #{@tracking_number}, #{@transaction_id}, #{order.quantity}, #{order.completed_at}, #{(e.message || '').delete(',')}, #{(order.ship_address.country.try(:name) || '').delete(',')}"]
        shipment = order.shipment
        shipment.tracking = nil
        shipment.save
      end
    end
    send_success_report
    send_failure_report
  end

  # fetch order ids that need to be sync
  def fetch_order_ids(zones)
    return if zones.blank?
    orders = Spree::Order.joins(ship_address: [{ country: :zones }]).where(['spree_zones.id in (?) and DATE(spree_orders.completed_at) >= ?', zones.map(&:id), Settings['order_sync_date']['asendia']]).unfulfilled
    orders.present? ? orders.map(&:id).uniq : nil
  end

  # update the shipping info in order
  def process_order
    result = begin
               JSON.parse(@response)['Result'].first
             rescue
               nil
             end
    return if result.blank?
    result['Status'].casecmp('success').zero? ? update_order(result) : create_asendia_shipment_record(result['Status'], result['Error'])
  end

  # update the order tracking no and shipment state
  def update_order(result)
    create_asendia_shipment_record(result['Status'], result['Error'])
    @transaction_id = result['ParcelId']
    @tracking_number = nil
    shipment = @order.shipment
    shipment.tracking = @tracking_number
    shipment.save
    shipment.ship!
    @order.line_items.each do |line_item|
      @success_orders << ["#{@order.number}, #{line_item.sku}, #{@tracking_number}, #{@transaction_id}, #{line_item.quantity}, #{@order.completed_at}, #{(@order.ship_address.country.try(:name) || '').delete(',')}"]
    end
  end

  # send success order report
  def send_success_report
    return if @success_orders.blank?
    success_orders = ['Order, SKU, Tracking, ParcelId, Quantity, Date, Country'] + @success_orders
    Spree::AsendiaMailer.csv(success_orders.join("\n"), 'asendia', "Sand & Sky : ASENDIA Shipments Report(#{Time.now.strftime('%d/%m/%Y')})").deliver
  end

  # send failed order report
  def send_failure_report
    return if @failed_orders.blank?
    failed_orders = ['Order, Tracking, ParcelId, Quantity, Date, Error_Message, Country'] + @failed_orders
    Spree::AsendiaMailer.csv(failed_orders.join("\n"), 'asendia', "Sand & Sky : ASENDIA Failed Shipments Report(#{Time.now.strftime('%d/%m/%Y')})").deliver
  end

  # Create a asendia shipment record
  def create_asendia_shipment_record(status_code, status_message)
    AsendiaOrder.create(order_number: @order.number, status_code: status_code, status_message: status_message, raw_request: @request, raw_response: @response, transaction_number: @transaction_id)
  end
end
