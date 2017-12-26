Spree::BaseHelper.class_eval do
  def get_affiliate(order_id, line_item_id)
    session[:affiliate_orders].present? && session[:affiliate_orders][order_id.to_s].present? ? session[:affiliate_orders][order_id.to_s][line_item_id.to_s] : ''
  end

  def get_order_affiliate(order_id)
    session[:affiliate_orders].present? && session[:affiliate_orders][order_id.to_s].present? ? 'Affiliate-' + session[:affiliate_orders][order_id.to_s].select { |_k, v| v.present? }.values.join('/') : ''
  end

  def get_order_gta_affiliation(order_id)
    affiliation_name = get_order_affiliate(order_id)
    affiliation_name.blank? ? current_store.name : affiliation_name
  end
end
