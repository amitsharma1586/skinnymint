module Spree
  module Shipments
    # Innotrac class manage innotrac shipment
    class Innotrac
      attr_reader :order, :ship_address, :http_url, :http_port, :http_method, :http_username,
                  :http_password, :project_code, :telemarketer, :promotion, :payment_plan,
                  :ftp_username, :ftp_password, :ftp_url, :handle_skus

      def initialize(order_id = nil)
        @order = order_id.present? ? Spree::Order.find_by_id(order_id) : nil
        @ship_address = @order.try(:ship_address)
        @http_url = INNOTRAC_CONFIG['gateway']
        @http_port = INNOTRAC_CONFIG['port']
        @http_method = INNOTRAC_CONFIG['post_url']
        @http_username = INNOTRAC_CONFIG['username']
        @http_password = INNOTRAC_CONFIG['password']
        @project_code = INNOTRAC_CONFIG['project_code']
        @telemarketer = INNOTRAC_CONFIG['telemarketer']
        @promotion = INNOTRAC_CONFIG['promotion']
        @payment_plan = INNOTRAC_CONFIG['payment_plan']
        @ftp_username = INNOTRAC_CONFIG['ftp_username']
        @ftp_password = INNOTRAC_CONFIG['ftp_password']
        @ftp_url = INNOTRAC_CONFIG['ftp_url']
        @handle_skus = INNOTRAC_CONFIG['handle_skus']
      end

      def upload(inno_xml)
        http = Net::HTTP.new(http_url, http_port)
        http.open_timeout = 600
        http.read_timeout = 600
        http.use_ssl = true
        http.post(http_method, inno_xml, 'Content-Type' => 'text/xml')
      end

      def to_xml
        return if order.blank?
        namespaces = { 'xmlns:soap' => 'http://www.w3.org/2003/05/soap-envelope', 'xmlns:inoc' => 'http://innotrac.reno/webservices/InocOrders' }
        line_items = order.line_items
        xml_obj = Nokogiri::XML::Builder.new do |xml|
          xml[:soap].Envelope namespaces do
            xml[:soap].Header
            xml[:soap].Body do
              xml['inoc'].PostOrderBatch do
                xml['inoc'].postOrderBatchRequest do
                  xml['inoc'].WSAuthorization do
                    xml['inoc'].Username http_username
                    xml['inoc'].Password http_password
                  end
                  xml['inoc'].OrderBatch do
                    xml['inoc'].TransmissionBatchID '001'
                    xml['inoc'].TransmissionSource 'IN'
                    xml['inoc'].TransmissionDate DateTime.now.new_offset(0)
                    xml['inoc'].Telemarketer telemarketer
                    xml['inoc'].RerunCount '0'
                    xml['inoc'].NumberOfOrders '1'
                    xml['inoc'].CustomerInfoOnly 'N'
                    xml['inoc'].Customer do
                      xml['inoc'].SerialID order.number
                      xml['inoc'].Project project_code
                      xml['inoc'].ClientCustomer '0'
                      xml['inoc'].FirstName order.ship_address.firstname
                      xml['inoc'].LastName order.ship_address.lastname
                      xml['inoc'].Address1 order.ship_address.address1
                      xml['inoc'].Address2 order.ship_address.address2
                      xml['inoc'].City order.ship_address.city
                      xml['inoc'].State shipping_state
                      xml['inoc'].Zip order.ship_address.zipcode
                      xml['inoc'].Country shipping_country
                      xml['inoc'].DayPhone order.ship_address.phone.gsub(/\D/, '')
                      xml['inoc'].Email do
                        xml['inoc'].EmailAddress order.email
                        xml['inoc'].EmailFlag 'P'
                      end
                      xml['inoc'].Order do
                        xml['inoc'].PurchaseOrder order.number
                        xml['inoc'].Promotion promotion
                        xml['inoc'].Media
                        xml['inoc'].BaseContinuityOrderFlag 'N'
                        xml['inoc'].ContinuityCode
                        xml['inoc'].OrderCategory
                        xml['inoc'].OrderDate DateTime.parse(order.created_at.to_s)
                        xml['inoc'].OrderReferenceNo1 order.number
                        xml['inoc'].UserId 'CartUser'
                        xml['inoc'].ShipFeeService 'S'
                        xml['inoc'].ShipCodeService 'S'
                        xml['inoc'].ResidentialCommercialFlag 'R'
                        xml['inoc'].PricingCalculationMethod 'M'
                        xml['inoc'].ShippingCalculationMethod 'M'
                        xml['inoc'].PaymentPlan payment_plan
                        xml['inoc'].OrderShipTo do
                          xml['inoc'].ShipToFirstName order.ship_address.firstname
                          xml['inoc'].ShipToLastName order.ship_address.lastname
                          xml['inoc'].ShipToAddress1 order.ship_address.address1
                          xml['inoc'].ShipToAddress2 order.ship_address.address2
                          xml['inoc'].ShipToCity order.ship_address.city
                          xml['inoc'].ShipToState shipping_state
                          xml['inoc'].ShipToZip order.ship_address.zipcode
                          xml['inoc'].ShipToCountry shipping_country
                          xml['inoc'].ShipToPhone order.ship_address.phone.gsub(/\D/, '')
                          xml['inoc'].ShipFeeService 'S'
                          xml['inoc'].ShipCodeService 'S'
                          xml['inoc'].ResidentialCommercialFlag 'R'
                          line_items.each_with_index do |item, i|
                            xml['inoc'].OrderItems do
                              xml['inoc'].SKU item.sku
                              xml['inoc'].Quantity item.quantity
                              xml['inoc'].LineNumber i + 1
                            end
                          end
                        end
                        xml['inoc'].Payment do
                          xml['inoc'].CreditCard do
                            xml['inoc'].SequenceNo '0'
                            xml['inoc'].CreditCardNumber
                            xml['inoc'].ExpirationDate
                            xml['inoc'].CVV2Code
                            xml['inoc'].CardHolderFlag 'S'
                          end
                        end
                      end
                    end
                  end
                end
              end
            end
          end
        end
        xml_obj.to_xml
      end

      def sync_with_ftp
        ftp_service = FtpService.new ftp_url, ftp_username, ftp_password
        files = ftp_service.download_dir 'outbound'

        parsed = files.flat_map do |file|
          parse file
        end

        orders_with_tracking_numbers = parsed.each_with_object({}) do |(_, order_no, tracking_no), hash|
          hash[order_no] = tracking_no
        end

        order_nos = orders_with_tracking_numbers.keys

        orders = Spree::Order.unfulfilled.where(number: order_nos)
        orders.each do |order|
          next unless orders_with_tracking_numbers[order.number].present?
          shipment = order.shipment
          shipment.tracking = orders_with_tracking_numbers[order.number]
          shipment.save
          shipment.ship!
        end

        # files.each do |file|
        #   filename = file.split('/').last
        #   ftp_service.move "/outbound/#{filename}", "/archive/outbound/#{filename}"
        # end

        parsed.map { |text| text.join ',' }.join "\n"
      end

      def confirmation_email(order_csv)
        Spree::InnotracMailer.csv(order_csv, 'innotrac', "#{telemarketer} : Innotrac Shipments Report(#{Time.now.strftime('%d/%m/%Y')})").deliver
      end

      def parse(filename)
        raw_xml = File.open(filename)
        xml = Nokogiri::XML(raw_xml)
        xml.remove_namespaces!

        order_status_nodes = xml.xpath('//OrderStatus')
        order_status_nodes.map do |order|
          [order.xpath('.//INOCOrderNumber').text,
           order.xpath('.//PONumber').text,
           order.xpath('.//TrackingID').text,
           handle_skus.invert.fetch(order.xpath('.//SKU').text, order.xpath('.//SKU').text),
           order.xpath('.//SKUStatus').text]
        end
      end

      def shipping_state
        if ship_address.country.iso == 'VI'
          'VI'
        else
          ship_address.state.try(:abbr)
        end
      end

      def shipping_country
        if ship_address.country.iso == 'CA'
          'CN'
        elsif ship_address.country.iso == 'VI'
          US
        else
          ship_address.country.iso
        end
      end
    end
  end
end
