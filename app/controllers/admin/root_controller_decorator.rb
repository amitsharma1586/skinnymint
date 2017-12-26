Spree::Admin::RootController.class_eval do
  skip_before_action :authorize_admin
  before_action :spree_authenticate_user

  def index
    redirect_to admin_root_redirect_path
  end

  protected

  # Redirect admin user to specific page based on roles
  def admin_root_redirect_path
    role_name = spree_current_user.spree_roles.collect(&:name).first
    case role_name
    when 'reports'
      return  spree.admin_reports_path
    when 'designer'
      return  spree.admin_pages_path
    when 'marketing executive'
      return  spree.admin_products_path
    else
      return spree.admin_orders_path
    end
  end
end
