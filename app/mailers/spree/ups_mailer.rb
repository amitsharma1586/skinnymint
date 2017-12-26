module Spree
  # ups api mailer
  class UpsMailer < BaseMailer
    include EmailOrderReport
  end
end
