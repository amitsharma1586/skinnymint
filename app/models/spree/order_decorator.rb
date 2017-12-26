Spree::Order.class_eval do
  # scopes
  scope :unfulfilled, -> { where(state: 'complete', payment_state: %w(paid credit_owed), shipment_state: %w(ready)) }
  scope :shipped, -> { where(state: 'complete', payment_state: %w(paid credit_owed), shipment_state: %w(shipped)) }

  remove_checkout_step :confirm

  # change order number starting from R to S
  before_validation(on: :create) do
    self.number = nil
    generate_number(prefix: 'S')
  end

  # this is use for skip delivery method from front end
  def needs_delivery?
    # can write logic here for delivery methods
    false
  end

  def select_default_shipping
    create_proposed_shipments # creates the shippings
    shipments.first.update_amounts # uses the first shippings
    update_totals # updates the order
  end

  def send_chain(methods_chain)
    methods_chain.split('.').inject(self) { |o, a| o.send(a) }
  end

  def payment_method_type
    payments.map(&:payment_method).map(&:name).join(', ')
  end

  def unfulfilled?
    complete? && payment_paid_or_credit && shipment_ready
  end

  def payment_paid_or_credit
    payment_state == 'paid' || payment_state == 'credit_owed'
  end

  def shipment_ready
    shipment_state == 'ready'
  end

  def tracking=(tracking)
    shipment.tracking = tracking
  end

  def tracking
    shipment.tracking
  end

  def tracking_url
    shipping_method.present? ? shipment.tracking_url : "No shipping method provided for tracking #{tracking}"
  end

  def shipping_method
    @shipping_method ||= shipment.shipping_method
  end

  # Return the skus for an order
  def item_skus
    line_items.map(&:sku).join(', ')
  end

  # Return order skus along with respective quantity
  def item_skus_with_quantity
    line_items.map { |line| "#{line.sku}-#{line.quantity}" }.join(', ')
  end

  # Return order's innotrack response
  def innotrac_response
    InnotracOrder.where(order_number: self.number).first
  end

  # Return the full to_address of order
  def full_order_to_address
    ship_address.address1 + ' ' + ship_address.address2
  end

  # Return the order receiver's full name
  def recipient_full_name
    ship_address.first_name + ' ' + ship_address.last_name
  end

  # Return the first shipment of an order
  def shipment
    @shipment ||= shipments.first
  end

  def apply_gwp_promo_code(coupon_code)
    promo = Spree::Promotion.find_by_code(coupon_code)
    if promo.present?
      if self.promotions.include?(promo)
        self.contents.update_cart(coupon_code: coupon_code)
      else
        self.coupon_code = coupon_code
        Spree::PromotionHandler::Coupon.new(self).apply
      end
    end
  end

  def confirm_fulfilled(tracking_code)
    shipment.tracking = tracking_code
    shipment.save
    shipment.ship! unless shipment.state == 'shipped'
    update(shipment_state: 'shipped') if shipment.state == 'shipped' && shipment_state == 'ready'
  end
end
