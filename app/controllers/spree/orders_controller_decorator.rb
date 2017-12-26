Spree::OrdersController.class_eval do
  before_action :apply_product_promotion, only: [:edit, :update]

  private

  def apply_product_promotion
    return if current_order.blank?
    current_order.variants.each do |variant|
      discount_code = variant.product.properties.select { |s| s.name == 'discount_code' }.first
      next if discount_code.blank?
      discount_code.product_properties.each do |discount_property|
        current_order.apply_gwp_promo_code(discount_property.value)
      end
    end
  end
end
