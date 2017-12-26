# Manage Fulfillment API request and response
class FulfillmentOrder < ActiveRecord::Base
  include JsonCheck

  def response
    response_hash = Hash.from_xml raw_response
    statuses = begin
              response_hash['Envelope']['Body']['PostOrderBatchResponse']['PostOrderBatchResult']['Orders']['OrderData']['OrderStatus']['Status']
            rescue
              []
            end
    statuses.class.name == 'Hash' ? statuses['Description'] : statuses.map { |s| s['Description'] }.join(' ')
  end

  # Check is order synced and get trackign no.
  def self.synced?(order_number)
    shipment = FulfillmentOrder.order(status_code: :desc).find_by_order_number(order_number)
    result = false
    if shipment.present? && shipment.raw_response.present? && shipment.valid_json?(shipment.raw_response)
      result = JSON.parse(shipment.raw_response)['tracking_code'].present?
    end
    result
  end
end
