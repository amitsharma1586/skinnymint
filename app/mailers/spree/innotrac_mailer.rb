module Spree
  # Manage Innotrac API mailer
  class InnotracMailer < BaseMailer
    include EmailOrderReport
  end
end
