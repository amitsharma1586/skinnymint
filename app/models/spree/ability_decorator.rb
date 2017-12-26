# Ability file for authenticate roles
class AbilityDecorator
  include CanCan::Ability
  def initialize(user)
    role_name = user.spree_roles.collect(&:name).first
    user.respond_to?(:has_spree_role?) ? check_access(role_name) : nil
  end

  # Check provided access for current role type
  def check_access(role_name)
    role_type = ['admin', 'qa', 'developer', 'ops manager', 'ops executive', 'designer', 'marketing manager', 'marketing executive', 'reports', 'agent']
    role_type.include?(role_name) ? send(role_name.squish.tr(' ', '_') + '_can_access_resources') : 'Not Authorized'
  end

  def admin_can_access_resources
    can :manage, :all
  end

  def qa_can_access_resources
    can [:admin, :index], [Spree::Order, Spree::Product, Spree::OptionType,
                           Spree::Property, Spree::Prototype, Spree::Taxonomy,
                           Spree::Taxon, Spree::Admin::ReportsController,
                           Spree::Promotion, Spree::PromotionCategory,
                           Spree::PromotionCategory, Spree.user_class,
                           Spree::TaxCategory, Spree::TaxRate,
                           Spree::Zone, Spree::Country, Spree::State,
                           Spree::PaymentMethod, Spree::ShippingMethod,
                           Spree::ShippingCategory, Spree::StockTransfer,
                           Spree::StockLocation, Spree::Tracker,
                           Spree::RefundReason, Spree::ReimbursementType,
                           Spree::ReturnAuthorizationReason, Spree::Role,
                           Spree::Page]
    can [:admin, :index, :edit, :update], [Spree::Store]
    can [:admin, :index, :edit, :update], :mail_methods
    can [:admin, :manage], [:general_settings, Spree::EditorSetting]
  end

  def developer_can_access_resources
    can [:admin, :index], [Spree::Order, Spree::Role]
    can [:admin, :manage], [Spree::Store]
    can [:admin, :index, :edit, :update], [Spree::Product, Spree::OptionType,
                                           Spree::Property, Spree::Prototype,
                                           Spree::Taxonomy, Spree::Taxon,
                                           Spree::Promotion,
                                           Spree::PromotionCategory, :mail_methods, Spree::EditorSetting,
                                           :general_settings, Spree::TaxCategory,
                                           Spree::TaxRate, Spree::Zone, Spree::Country,
                                           Spree::State, Spree::PaymentMethod,
                                           Spree::ShippingMethod, Spree::ShippingCategory,
                                           Spree::StockTransfer, Spree::StockLocation,
                                           Spree::Tracker, Spree::RefundReason,
                                           Spree::ReimbursementType,
                                           Spree::ReturnAuthorizationReason, Spree::Page]
  end

  def ops_manager_can_access_resources
    can [:admin, :index, :edit, :update], Spree::Order
    can [:admin, :index], [Spree::Admin::ReportsController, Spree::Promotion,
                           Spree::Store, Spree::Zone, Spree::Country, Spree::State,
                           Spree::PaymentMethod, Spree::RefundReason,
                           Spree::StockTransfer, Spree::StockLocation]
    can [:admin, :index, :edit, :update], [Spree::ShippingMethod, Spree::ShippingCategory,
                                           Spree::Role]
  end

  def ops_executive_can_access_resources
    can [:admin, :index, :edit, :update], Spree::Order
    can [:admin, :index], [Spree::Admin::ReportsController, Spree::Promotion]
  end

  def designer_can_access_resources
    can [:admin, :manage], Spree::Store
    can [:admin, :index, :edit, :update], [Spree::EditorSetting,
                                           Spree::Page]
  end

  def marketing_manager_can_access_resources
    can [:admin, :index], [Spree::Order, Spree::Product, Spree::Admin::ReportsController,
                           Spree::Promotion, Spree::Zone, Spree::Country, Spree::State,
                           Spree::PaymentMethod, Spree::ShippingMethod, Spree::ShippingCategory,
                           Spree::Page]
    can [:admin, :manage], Spree::Store
  end

  def marketing_executive_can_access_resources
    can [:admin, :index],  [Spree::Order, Spree::Product, Spree::Admin::ReportsController,
                            Spree::Promotion, Spree::Page]
  end

  def reports_can_access_resources
    can [:admin, :index], [Spree::Order, Spree::Admin::ReportsController]
  end

  def agent_can_access_resources
    can [:admin, :index, :edit, :update, :resend], [Spree::Address, Spree::Order]
    can [:admin, :index], Spree::Payment
    can [:edit, :update], Spree::User
  end
end
Spree::Ability.register_ability(AbilityDecorator)
