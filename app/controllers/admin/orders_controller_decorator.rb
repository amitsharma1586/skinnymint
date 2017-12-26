require 'csv'

Spree::Admin::OrdersController.class_eval do
  def index
    params[:q] ||= {}
    params[:q][:completed_at_not_null] ||= '1' if Spree::Config[:show_only_complete_orders_by_default]
    if params[:q][:completed_at_not_null].present?
      params[:q][:s] ||= 'completed_at desc'
      params[:q][:completed_at_gt] = params[:q][:created_at_gt]
      params[:q][:completed_at_lt] = params[:q][:created_at_lt]
    else
      params[:q][:s] ||= 'created_at desc'
    end
    @search = Spree::Order.accessible_by(current_ability, :index).ransack(params[:q])
    @orders = @search.result(distinct: true).page(params[:page]).per(params[:per_page] || Spree::Config[:orders_per_page])
    respond_to do |format|
      format.html
      format.csv do
        reporter = UnfulfilledOrdersReporter.new(@search.result(distinct: true), template_name: params[:template_name])
        send_data reporter.to_csv, type: 'text/csv; charset=utf-8; header=present',
                                   disposition: "attachment; filename=download_#{params[:template_name]}s_ss_#{Time.now.strftime('%d-%m-%Y')}.csv"
      end
    end
  end

  def upload_fulfilled
    return unless params[:csv].present?
    orders_hash = {}
    missing_trackings = []
    CSV.parse(params[:csv].read, headers: true).each do |row|
      order_number = row['Order Number'].try(:strip)
      tracking     = row['Tracking Number'].try(:strip)
      orders_hash[order_number] = tracking
      missing_trackings << order_number if tracking.blank?
    end
    @all_orders = Spree::Order.where(number: orders_hash.keys)
    @unfulfilled_orders = @all_orders.unfulfilled
    @already_shipped_orders = @all_orders.shipped
    @missing_tracking_orders = missing_trackings.present? ? Spree::Order.where(number: missing_trackings) : []
    @not_found_orders = orders_hash.keys - @all_orders.map(&:number)
  end

  def confirm_fulfilled
    orders_with_tracking_numbers = params[:orders]
    order_ids = orders_with_tracking_numbers.keys
    orders = Spree::Order.unfulfilled.where(id: order_ids)
    orders.map { |s| s.confirm_fulfilled(orders_with_tracking_numbers[s.id.to_s]) }
    redirect_to admin_orders_path
  end
end
