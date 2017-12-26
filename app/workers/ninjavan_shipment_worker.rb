# ninjavan worker to sync orders on ninjavan api using background jobs
class NinjavanShipmentWorker
  include Sidekiq::Worker
  include NinjavanApi

  def perform(order_ids)
    @success_orders = []
    @failed_orders = []
    orders = Spree::Order.joins({ ship_address: :country }, :variants, :shipments).order('spree_countries.name, spree_variants.sku').where(id: order_ids).where('spree_shipments.tracking is ?', nil)
    @token = create_access_token
    send_order_to_ninjavan(orders) if @token.present?
    send_success_report if @success_orders.present?
    send_failure_report if @failed_orders.present?
  end

  # process order for ninjavan
  def send_order_to_ninjavan(orders)
    orders.to_a.uniq.each do |order|
      begin
        @order = order
        @request, @order_creation_response, @order_information = add_order(order.id, @token)
        @order_creation_response.try(:code) == 202 ? process_order : create_ninjavan_shipment_record('Failure', 'order shipment not available')
      rescue StandardError => e
        @failed_orders << ["#{order.number}, #{@tracking_number}, #{@transaction_id}, #{order.quantity}, #{order.completed_at}, #{(e.message || '').delete(',')}, #{(order.ship_address.country.try(:name) || '').delete(',')}"]
        shipment = order.shipment
        shipment.tracking = nil
        shipment.save
      end
    end
  end

  # update the shipping info in order
  def process_order
    result = JSON.parse(@order_creation_response.body).first
    order_inf = JSON.parse(@order_information.body)
    result ? update_order(result, order_inf) : create_ninjavan_shipment_record(order_inf['transactions'].first['status'], result['Error'])
  end

  def update_order(result, order_inf)
    @transaction_id = result['id']
    @tracking_number = order_inf['tracking_id']
    create_ninjavan_shipment_record(order_inf['transactions'].first['status'], result['Error'])
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
    success_orders = ['Order, SKU, Tracking, ParcelId, Quantity, Date, Country'] + @success_orders
    Spree::NinjavanMailer.csv(success_orders.join("\n"), 'ninjavan', "Sand & Sky : NINJAVAN Shipments Report(#{Time.now.strftime('%d/%m/%Y')})").deliver
  end

  # send failed order reports
  def send_failure_report
    failed_orders = ['Order, Tracking, ParcelId, Quantity, Date, Error_Message, Country'] + @failed_orders
    Spree::NinjavanMailer.csv(failed_orders.join("\n"), 'ninjavan', "Sand & Sky : NINJAVAN Failed Shipments Report(#{Time.now.strftime('%d/%m/%Y')})").deliver
  end

  def create_ninjavan_shipment_record(status_code, status_message)
    NinjavanOrder.create(order_number: @order.number, status_code: status_code, status_message: status_message, raw_request: @request, raw_response: @order_creation_response, transaction_number: @transaction_id)
  end

  # ninjavan api call for getting an access token
  def create_access_token
    url_for_access_token = ENV['NINJAVAN_URL_FOR_ACCESS_TOKEN']
    api_params_for_access_token = {
      client_id: ENV['NINJAVAN_CLIENT_ID'],
      client_secret: ENV['NINJAVAN_CLIENT_SECRET'],
      grant_type: 'client_credentials'
    }.to_json
    access_token_response = RestClient.post(url_for_access_token, api_params_for_access_token, content_type: :json)
    access_token_response = JSON.parse(access_token_response.body)
    access_token_response['access_token']
  end
end
