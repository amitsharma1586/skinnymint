Spree::CheckoutController.class_eval do
  include Spree::Shipments::AramexAddressValidator

  def before_delivery
    @order.select_default_shipping
    @order.next # go to next step
    # default logic for finalizing unless he can't select payment_method
    if @order.completed?
      session[:order_id] = nil
      flash.notice = Spree.t(:order_processed_successfully)
      redirect_to completion_route
    else
      redirect_to checkout_state_path(@order.state)
    end
  end

  # fetch cities from aramex api
  def fetch_cities_from_aramex
    response = []
    zones = Spree::ShippingMethod.where(['LOWER(admin_name) like ?', '%aramex%']).map(&:zones).flatten
    if zones.map(&:country_ids).flatten.uniq.include?(params['country_code'].to_i)
      country = Spree::Country.find(params['country_code'])
      response = JSON.parse(fetch_cities(country.iso))['Cities']
    end
    respond_to do |format|
      format.json { render json: response, status: 200 }
    end
  end
end
