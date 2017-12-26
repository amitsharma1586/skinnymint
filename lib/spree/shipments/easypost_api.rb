module Spree
  module Shipments
    # easypost api integration
    module EasypostApi
      include JsonCheck

      # Add an order using easypost api
      def add_order(order_id, carrier)
        @carrier = carrier
        @order = Spree::Order.find(order_id)
        @ship_carrier = Settings['supported_carriers'].include?(carrier) ? ENV["#{carrier.upcase}_CARRIER_ID"] : nil
        @ship_carrier.present? && @order.shipment.present? ? create_shipment : return_error
      end

      # create shipment in easypost
      def create_shipment
        to_address = create_address(name: @order.recipient_full_name,
                                    street1: @order.ship_address.address1,
                                    street2: @order.ship_address.address2,
                                    city: @order.ship_address.city,
                                    state: @order.ship_address.state.try(:name) || '',
                                    zip: @order.ship_address.zipcode,
                                    country: @order.ship_address.country.try(:iso) || '',
                                    phone: @order.ship_address.phone,
                                    email: @order.email)

        from_address = if @carrier == 'auspost'
                         create_address(name: Settings['shipping_address']['company_name'],
                                        street1: Settings['shipping_address']['auspost']['street1'],
                                        city: Settings['shipping_address']['auspost']['city'],
                                        state: Settings['shipping_address']['auspost']['state'],
                                        zip: Settings['shipping_address']['auspost']['zipcode'],
                                        country: Settings['shipping_address']['auspost']['country'],
                                        phone: Settings['shipping_address']['auspost']['phone'],
                                        email: Settings['shipping_address']['email'])
                       else
                         create_address(name: Settings['shipping_address']['company_name'],
                                        street1: Settings['shipping_address']['street1'],
                                        city: Settings['shipping_address']['city'],
                                        state: Settings['shipping_address']['state'],
                                        zip: Settings['shipping_address']['zipcode'],
                                        country: Settings['shipping_address']['country'],
                                        phone: Settings['shipping_address']['phone'],
                                        email: Settings['shipping_address']['email'])
                       end

        parcel = EasyPost::Parcel.create(
          length: Settings['parcel']['length'],
          width: Settings['parcel']['width'],
          height: Settings['parcel']['height'],
          weight: Settings['parcel']['weight']
        )

        customs_info = EasyPost::CustomsInfo.create(
          contents_type: Settings['parcel']['easypost']['contents_type'],
          contents_explanation: Settings['parcel']['description'],
          eel_pfc: Settings['parcel']['easypost']['eel_pfc'],
          non_delivery_option: Settings['parcel']['easypost']['non_delivery'],
          restriction_type: Settings['parcel']['easypost'][' restriction_type'],
          customs_items: [{
            description: Settings['parcel']['description'],
            quantity: @order.item_count.to_i,
            value: Settings['parcel']['easypost']['value'],
            weight: Settings['parcel']['weight'],
            origin_country: Settings['shipping_address']['country'],
            hs_tariff_number: Settings['parcel']['hs_tariff_number'],
            currency: Settings['parcel']['currency']
          }]
        )

        @shipment = EasyPost::Shipment.create(
          to_address: to_address,
          from_address: from_address,
          parcel: parcel,
          customs_info: customs_info,
          carrier_accounts: [@ship_carrier],
          options: { print_custom_1: @order.item_skus_with_quantity, print_custom_2: @order.number, label_format: 'PNG', currency: 'SGD' }
        )
        @shipment.try(:id).present? && @shipment.try(:messages).present? ? return_shipment_errors : buy_shipment
      end

      # create address on easypost
      def create_address(params)
        EasyPost::Address.create(params)
      end

      # return error related to order and carrier intergation
      def return_error
        [nil, nil, @ship_carrier.present? ? 'Order shipment not avialable' : 'Shipment carrier integration not found']
      end

      # return shipment creation error given by api call
      def return_shipment_errors
        ["#{@shipment}.buy(no rates found for this shipment)", @shipment, @shipment]
      end

      # buy shipment
      def buy_shipment
        ["#{@shipment}.buy(#{@shipment.lowest_rate})", @shipment, @shipment.buy(rate: @shipment.lowest_rate)]
      end
    end
  end
end
