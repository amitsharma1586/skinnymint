# Controller to receive webhooks from easypost api
module Spree
  module Api
    # receive batch printing webhook
    class WebHooksController < ApplicationController
      # Receive Easypost batch label created webhook
      def receive_webhook
        begin
          @result = params['result']
          generate_and_send_labels if @result.present? && @result['object'] == 'Batch'
        rescue StandardError
          Spree::OrderMailer.send_label_generate_failed_report('Sand & Sky', Time.now.strftime('%d/%m/%Y').to_s).deliver
        end
        render nothing: true
      end

      # Generate and sent labels email
      def generate_and_send_labels
        date = DateTime.parse(@result['created_at'])
        creation_date = date.strftime('%d/%m/%Y')
        case @result['state']
        when 'created', 'purchased'
          batch = EasyPost::Batch.retrieve(@result['id'])
          batch.label(file_format: 'pdf')
        when 'label_generated'
          pdf_url = (@result['label_url'].present? ? @result['label_url'] : nil)
          if pdf_url.present?
            carrier = find_carrier
            Spree::OrderMailer.send_labels_pdf(creation_date, carrier.gsub('Order', ''), pdf_url).deliver
          end
        when 'creation_failed', 'purchase_failed'
          carrier = find_carrier
          Spree::OrderMailer.send_label_generate_failed_report(carrier.gsub('Order', ''), creation_date).deliver
        end
      end

      # find the carrier for which the pdf generated
      def find_carrier
        if @result['shipments'].present?
          shipment_id = @result['shipments'].first['id']
          carrier = FulfillmentOrder.find_by_transaction_number(shipment_id).try(:type)
          carrier.present? ? carrier : 'Sand & Sky'
        else
          'Sand & Sky'
        end
      end
    end
  end
end
