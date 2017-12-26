Spree::OrderMailer.class_eval do
  # Send labels pdf for printing
  def send_labels_pdf(creation_date, carrier, pdf_url = nil, attachment = nil)
    @url = pdf_url
    @carrier = carrier
    @creation_date = creation_date
    attachments["#{carrier}-order-labels-#{@creation_date}.pdf"] = attachment if attachment.present?
    mail(to: Settings['labels_pdf_receiver_email'], from: Settings['unfulfilled_email']['from'], subject: "Sand & Sky : #{@carrier.upcase} Shipments Label(#{@creation_date})")
  end

  # Send labels generation failed event error
  def send_label_generate_failed_report(carrier, creation_date)
    @creation_date = creation_date
    @carrier = carrier
    mail(to: Settings['labels_pdf_receiver_email'], from: Settings['unfulfilled_email']['from'], subject: "Sand & Sky : #{@carrier.upcase} Labels Generation Failed(#{@creation_date})")
  end
end
