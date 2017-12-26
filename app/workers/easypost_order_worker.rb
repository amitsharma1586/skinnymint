# easypost worker to sync orders on easypost api using background jobs
class EasypostOrderWorker
  include Sidekiq::Worker
  include Spree::Shipments::EasypostApi
  include Spree::Shipments::ShipmentLabelGenerator

  def perform(carrier, order_ids = nil)
    carrier = carrier['name']
    zones = Spree::ShippingMethod.where(['LOWER(admin_name) like ?', "%#{carrier}%"]).map(&:zones).flatten
    order_ids = order_ids.blank? ? fetch_order_ids(zones, carrier) : order_ids
    @success_orders, @failed_orders, @shipment_ids, @batch_shipment_ids = Array.new(4) { [] }
    @carrier = carrier
    orders = Spree::Order.joins({ ship_address: :country }, :variants, :shipments).order('spree_variants.sku').where(id: order_ids).where('spree_shipments.tracking is ?', nil)
    orders.to_a.uniq.each do |order|
      begin
        @order = order
        FulfillmentOrder.synced?(order.number) ? next : process_request
      rescue StandardError => e
        @failed_orders << ["#{order.number}, #{@tracking_response.try(:tracking_code)}, #{order.quantity}, #{order.completed_at}, #{(e.message || '').delete(',')}, #{(order.ship_address.country.try(:name) || '').delete(',')}"]
        shipment = order.shipment
        shipment.tracking = nil
        shipment.save
        create_shipment_record('Failure', e.message)
      end
    end
    create_batch_label
    send_success_report
    send_failure_report
  end

  # fetch order ids that need to be sync
  def fetch_order_ids(zones, carrier)
    return if zones.blank?
    orders = Spree::Order.joins(ship_address: [{ country: :zones }]).where(['spree_zones.id in (?) and DATE(spree_orders.completed_at) >= ?', zones.map(&:id), Settings['order_sync_date'][carrier.to_s]]).unfulfilled
    orders.present? ? orders.map(&:id).uniq : nil
  end

  def process_request
    @request, @shipment_response, @tracking_response = add_order(@order.id, @carrier)
    @tracking_response.try(:id).present? && @tracking_response.try(:tracking_code).present? ? update_order : save_shipment_error
  end

  # update order for shipment information
  def update_order
    create_shipment_record('success', '')
    @batch_shipment_ids << { id: @tracking_response.id }
    @shipment_ids << @tracking_response.id
    shipment = @order.shipment
    shipment.tracking = @tracking_response.try(:tracking_code)
    shipment.save
    shipment.ship!
    @order.line_items.each do |line_item|
      @success_orders << ["#{@order.number}, #{line_item.sku}, #{@tracking_response.try(:tracking_code)}, #{line_item.quantity}, #{@order.completed_at}, #{(@order.ship_address.country.try(:name) || '').delete(',')}"]
    end
  end

  # save the shipment error for an order
  def save_shipment_error
    error_msg = @shipment_response.try(:id).present? && @shipment_response.try(:messages).present? ? @shipment_response.messages.map(&:message).join(' ') : @tracking_response
    @failed_orders << ["#{@order.number}, #{@tracking_response.try(:tracking_code)}, #{@order.quantity}, #{@order.completed_at}, #{(error_msg || '').delete(',')}, #{(@order.ship_address.country.try(:name) || '').delete(',')}"]
    create_shipment_record('Failure', error_msg)
  end

  # Create ups shipment record
  def create_shipment_record(status_code, status_message)
    case @carrier
    when 'ups'
      UpsOrder.create(order_number: @order.number, transaction_number: @tracking_response.try(:id), status_code: status_code, status_message: status_message, raw_request: @request, raw_response: @tracking_response)
    when 'aramex'
      AramexOrder.create(order_number: @order.number, transaction_number: @tracking_response.try(:id), status_code: status_code, status_message: status_message, raw_request: @request, raw_response: @tracking_response)
    when 'auspost'
      AuspostOrder.create(order_number: @order.number, transaction_number: @tracking_response.try(:id), status_code: status_code, status_message: status_message, raw_request: @request, raw_response: @tracking_response)
    else
      'please check carrier name'
    end
  end

  # generate batch and labels for synched orders
  def create_batch_label
    return if @batch_shipment_ids.blank?
    batch = EasyPost::Batch.create(shipments: @batch_shipment_ids)
    send_shipment_label if batch.id.present? && batch.state == 'created'
  rescue
    file = generate_pdf_label(@carrier, @shipment_ids)
    Spree::OrderMailer.send_labels_pdf(Time.now.strftime('%d/%m/%Y'), @carrier, nil, file).deliver
    File.delete("#{@carrier}-order-labels-#{Time.now.strftime('%d-%m-%Y')}.pdf") if File.exist?("#{@carrier}-order-labels-#{Time.now.strftime('%d-%m-%Y')}.pdf")
  end

  # send shipment labels pdf
  def send_shipment_label(batch)
    label = batch.label(file_format: 'pdf')
    Spree::OrderMailer.send_labels_pdf(Time.now.strftime('%d/%m/%Y'), @carrier, label['label_url']).deliver if label.state == 'label_generated' && label['label_url'].present?
  end

  # send success order report
  def send_success_report
    return if @success_orders.blank?
    success_orders = ['Order, SKU, Tracking, Quantity, Date, Country'] + @success_orders
    send_report_email(success_orders.join("\n"), "Sand & Sky : #{@carrier.upcase} Shipments Report(#{Time.now.strftime('%d/%m/%Y')})")
  end

  # send failed order report
  def send_failure_report
    return if @failed_orders.blank?
    failed_orders = ['Order, Tracking, Quantity, Date, Error_Message, Country'] + @failed_orders
    send_report_email(failed_orders.join("\n"), "Sand & Sky : #{@carrier.upcase} Failed Shipments Report(#{Time.now.strftime('%d/%m/%Y')})")
  end

  # Send order report email
  def send_report_email(report, report_title)
    case @carrier
    when 'ups'
      Spree::UpsMailer.csv(report, @carrier, report_title).deliver
    when 'aramex'
      Spree::AramexMailer.csv(report, @carrier, report_title).deliver
    when 'auspost'
      Spree::AuspostMailer.csv(report, @carrier, report_title).deliver
    else
      'please check carrier name'
    end
  end
end
