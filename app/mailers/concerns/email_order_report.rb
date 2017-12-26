# Manage Shipping API mailer
module EmailOrderReport
  extend ActiveSupport::Concern

  def csv(csv, type, report_title)
    time_stamp = Time.now.strftime('%Y-%m-%d-%H:%M:%S')
    attachments["#{type}-orders-#{time_stamp}.csv"] = csv
    @type = type
    mail  to: Settings['unfulfilled_email'][type], from: Settings['unfulfilled_email']['from'], subject: report_title.to_s
  end
end
