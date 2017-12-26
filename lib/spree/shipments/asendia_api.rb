require 'rest-client'
module Spree
  module Shipments
    # Asendia Api integration
    module AsendiaApi
      # Add an order in asendia shipment record
      def add_order(order_id)
        order = Spree::Order.find order_id
        if order.shipment.present?
          url = ENV['ASENDIA_ADD_ORDER_URL']
          api_params = {
            ApiToken: ENV['ASENDIA_API_KEY'],
            OrderList: [{
              OrderNumber: order.number,
              ServiceType: Settings['parcel']['asendia']['service_type'],
              Remark: order.item_skus,
              Consignee: order.recipient_full_name,
              Address1: order.ship_address.address1,
              Address2: order.ship_address.address2,
              Address3: ' ',
              City: order.ship_address.city,
              State: order.ship_address.state.try(:name) || '',
              CountryCode: order.ship_address.country.try(:iso) || '',
              ConsigneePhone: order.ship_address.phone,
              Zip: order.ship_address.zipcode,
              Email: order.email,
              Description: Settings['parcel']['description'],
              Value: Settings['parcel']['asendia']['value'],
              CustomsType: Settings['parcel']['customs_type'],
              Currency: Settings['parcel']['currency'],
              Weight: Settings['parcel']['weight']
            }]
          }.to_json

          ["RestClient.post(#{url}, #{api_params}, { content_type: :json })", make_api_call(url, api_params)]
        else
          [nil, { Status: 'Failure', Error: 'order shipment not available' }]
        end
      end

      # Make an api call
      def make_api_call(url, api_params)
        RestClient.post(url, api_params, content_type: :json)
      end
    end
  end
end
