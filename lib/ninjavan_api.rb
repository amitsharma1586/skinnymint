require 'rest-client'
# Ninjavan Api integration
module NinjavanApi
  # Add an order in ninjavan shipment record
  def add_order(order_id, token)
    order = Spree::Order.find order_id
    if order.shipment.present?
      url_for_order_creation = ENV['NINJAVAN_URL_FOR_ORDER_CREATION']
      api_params = {
        from_postcode: Settings['shipping_address']['zipcode'],
        from_address1: Settings['shipping_address']['street1'],
        from_city: Settings['shipping_address']['city'],
        from_country: Settings['shipping_address']['country'],
        from_email: Settings['shipping_address']['email'],
        from_name: Settings['shipping_address']['company_name'],
        from_contact: Settings['shipping_address']['phone'],
        to_postcode: order.ship_address.zipcode,
        to_address1: order.ship_address.address1,
        to_address2: order.ship_address.address2,
        to_city: order.ship_address.city,
        to_country: order.ship_address.country.try(:iso) || '',
        to_email: order.email,
        to_name: order.ship_address.full_name,
        to_contact: order.ship_address.phone,
        delivery_date: Date.today.strftime('%Y-%m-%d'),
        pickup_date: Date.today.strftime('%Y-%m-%d'),
        pickup_timewindow_id: -2,
        delivery_timewindow_id: 3,
        max_delivery_days: 3,
        type: 'Normal',
        parcels: [{
          parcel_size_id: 1,
          volume: Settings['parcel']['volume'],
          weight: Settings['parcel']['weight']
        }]
      }.to_json
      order_creation_response = make_api_call_for_order_creation(url_for_order_creation, api_params, token)
      order_creation_response_body = JSON.parse(order_creation_response.body)
      order_id = order_creation_response_body.first['id']
      order_information = make_api_call_for_getting_order(order_id, token)
      ["RestClient.Post(#{url_for_order_creation}, #{api_params}, { content_type: :json })", order_creation_response, order_information]
    else
      [nil, { Status: 'Failure', Error: 'order shipment not available' }]
    end
  end

  # Make an api call for order creation
  def make_api_call_for_order_creation(url, api_params, access_token)
    RestClient.post(url, api_params, Authorization: "Bearer #{access_token}", content_type: :json)
  end

  # Make an api call for getting an order
  def make_api_call_for_getting_order(order_id, access_token)
    url = ENV['NINJAVAN_URL_FOR_GETTING_ORDER'] + order_id
    RestClient.get(url, Authorization: "Bearer #{access_token}")
  end
end
