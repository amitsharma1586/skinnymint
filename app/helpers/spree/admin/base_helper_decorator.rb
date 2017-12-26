Spree::BaseHelper.class_eval do
  def user_can_view_order_tab
    !reports_role && !designer_role && !marketing_executive_role
  end

  def user_can_view_reports_tab_for_orders
    admin_role || ops_manager_role || ops_executive_role
  end

  def user_can_view_configuration_options(role)
    spree_current_user.has_spree_role?(role)
  end

  def user_can_view_mail_settings
    admin_role || developer_role || qa_role
  end

  def user_can_view_slide_locations
    admin_role || developer_role || qa_role || designer_role
  end

  def user_can_view_slides
    admin_role || developer_role || qa_role || designer_role
  end

  def user_can_view_rich_editor
    admin_role || developer_role || qa_role || designer_role
  end

  def admin_role
    spree_current_user.has_spree_role?('admin')
  end

  def qa_role
    spree_current_user.has_spree_role?('qa')
  end

  def developer_role
    spree_current_user.has_spree_role?('developer')
  end

  def designer_role
    spree_current_user.has_spree_role?('designer')
  end

  def reports_role
    spree_current_user.has_spree_role?('reports')
  end

  def ops_manager_role
    spree_current_user.has_spree_role?('ops manager')
  end

  def marketing_executive_role
    spree_current_user.has_spree_role?('marketing executive')
  end

  def ops_executive_role
    spree_current_user.has_spree_role?('ops executive')
  end
end
