module Spree
  module Shipments
    # shipments label generation
    module ShipmentLabelGenerator
      include JsonCheck
      # Generate labels pdf for shipments
      def generate_pdf_label(carrier, shipment_ids)
        label_urls = []
        shipments = FulfillmentOrder.where(transaction_number: shipment_ids)
        shipments.each do |shipment|
          if shipment.raw_response.present? && valid_json?(shipment.raw_response)
            data = JSON.parse(shipment.raw_response)
            label_urls << data['postage_label']['label_url'] if data['postage_label']['label_url'].present?
          end
        end
        create_pdf(carrier, label_urls) if label_urls.present?
      end

      # Create pdf file for labels
      def create_pdf(carrier, label_urls)
        Prawn::Document.generate("#{carrier}-order-labels-#{Time.now.strftime('%d-%m-%Y')}.pdf", page_size: 'TABLOID', page_layout: :landscape, left_margin: 50) do |pdf|
          label_urls.in_groups_of(2, false).each do |label|
            label.each_with_index do |value, index|
              ima = open(URI.parse(value))
              pdf.image Rails.root.join(ima), at: [index * 650, 650], width: 450, height: 700, overflow: :shrink_to_fit
            end
            pdf.start_new_page unless label.include?(label_urls.last)
          end
        end
        file = File.read("#{carrier}-order-labels-#{Time.now.strftime('%d-%m-%Y')}.pdf")
        file.valid_encoding? ? file : file.force_encoding('BINARY')
      rescue StandardError
        'something went wrong'
      end
    end
  end
end
