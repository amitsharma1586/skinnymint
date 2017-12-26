# Manage Innotrac API request and response
class InnotracOrder < FulfillmentOrder
  def response
    response_hash = Hash.from_xml raw_response
    statuses = begin
              response_hash['Envelope']['Body']['PostOrderBatchResponse']['PostOrderBatchResult']['Orders']['OrderData']['OrderStatus']['Status']
            rescue
              []
            end
    statuses.class.name == 'Hash' ? statuses['Description'] : statuses.map { |s| s['Description'] }.join(' ')
  end

  def upload
    order = Spree::Order.find_by_number(order_number)
    inno_obj = Spree::Shipments::Innotrac.new(order.id)
    inno_request = inno_obj.to_xml
    inno_response = inno_obj.upload(inno_request)
    response_xml = Nokogiri::XML(inno_response.body)
    response_xml.remove_namespaces!

    transaction_number = response_xml.xpath('//transactionNumber').text
    status_code = response_xml.xpath('//StatusCode').text
    status_message = response_xml.xpath('//StatusMessage').text
    if transaction_number.present?
      update_attributes!(number: order.number,
                         transaction_number: transaction_number,
                         status_code: status_code,
                         status_message: status_message,
                         raw_request: inno_request,
                         raw_response: response_xml.to_xml)
    else
      destroy
    end
  end

  def self.sync
    inno_obj = Spree::Shipments::Innotrac.new
    order_csv = inno_obj.sync_with_ftp
    inno_obj.confirmation_email(order_csv)
  end
end
