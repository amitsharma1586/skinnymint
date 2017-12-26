require 'csv'

Spree::Admin::ReportsController.class_eval do
  COUNTRY_SKU_NAME_HEADER = %w(Country\ Name SKU Total\ Count).freeze
  COUNTRY_SKU_NAME_TEMPLATE = [:country_name, :sku, :total_count].freeze
  COUNTRY_SKU_TOTAL_HEADER = %w(Country\ Name SKU Total\ Count).freeze
  COUNTRY_SKU_TOTAL_TEMPLATE = [:country_name, :sku, :total_count].freeze
  COUNTRY_TOTAL_HEADER = %w(Country\ Name Currency Total\ Sales Total\ Sales\ USD Total\ Count Average\ Revenue\ Per\ User).freeze
  COUNTRY_TOTAL_TEMPLATE = [:country_name, :currency, :country_total, :country_total_usd, :total_count, :arpu].freeze

  def initialize
    super
    Spree::Admin::ReportsController.add_available_report!(:country_sku_name, 'Sku sales per')
    Spree::Admin::ReportsController.add_available_report!(:country_sku_total, 'Sku sales per country')
    Spree::Admin::ReportsController.add_available_report!(:country_total, 'Table showing the sales per country per currency')
    Spree::Admin::ReportsController.add_available_report!(:sales_total, 'Sales Total For All Orders')
  end

  before_filter :search, only: [:country_sku_total, :country_total, :country_sku_name]

  def search
    params[:completed_at_gt] = if params[:completed_at_gt].blank?
                                 Date.today.beginning_of_day
                               else
                                 begin
                                   Time.zone.parse(params[:completed_at_gt])
                                 rescue
                                   Date.today.beginning_of_day
                                 end
                               end
    params[:completed_at_lt] = if params[:completed_at_lt].blank?
                                 Date.today.end_of_day
                               else
                                 begin
                                  Time.zone.parse(params[:completed_at_lt])
                                rescue
                                  Date.today.end_of_day
                                end
                               end
    @start_date = params[:completed_at_gt].strftime('%Y-%m-%d')
    @end_date = params[:completed_at_lt].strftime('%Y-%m-%d')
    @search = Spree::Order.complete.ransack(params[:q])
    @orders = @search.result
    @skus = Spree::Product.where.not(name: ['', nil]).map(&:name)
    @sku_names = Spree::Variant.where.not(sku: ['', nil]).map(&:sku)
    country_set = Set.new REDIS.keys('Country*').map { |key| key.split(':')[2] }
    @countries = Spree::Country.select(:iso, :name).where('iso in (?)', country_set).order(:name)
  end

  def country_sku_total
    @totals = {}
    (@start_date..@end_date).each do |date|
      key_pattern = params[:country].present? ? "SKU:#{date}:#{params[:country]}:#{params[:sku]}*" : "SKU:#{date}*"
      keys = REDIS.keys key_pattern
      keys.each do |key|
        value = REDIS.get key
        split_key = key.split ':'
        split_value = value.split ':'
        country = split_key[2]
        sku = split_key[3]
        total = split_value[0]
        country_name = split_value[1]
        total_key = "#{country}_#{sku}"
        @totals[total_key] = { country_name: country_name, sku: sku, total_count: 0 } unless @totals[total_key]
        @totals[total_key][:total_count] += total.to_i
      end
    end
    @totals = @totals.sort_by { |_key, value| value[:total_count] }.reverse
    respond_to do |format|
      format.html do
      end
      format.csv do
        send_data to_csv('country_sku_total', @totals), type: 'text/csv; charset=utf-8; header=present',
                                                        disposition: "attachment; filename=sku_sales-#{Time.now.strftime('%Y-%m-%d-%H:%M:%S')}.csv"
      end
    end
  end

  def country_sku_name
    @totals = {}
    (@start_date..@end_date).each do |date|
      key_pattern = params[:country].present? ? "SKUNAME:#{date}:#{params[:country]}:#{params[:sku]}*" : "SKUNAME:#{date}*"
      keys = REDIS.keys key_pattern
      keys.each do |key|
        value = REDIS.get key
        split_key = key.split ':'
        split_value = value.split ':'
        country = split_key[2]
        sku_name = split_key[3]
        total = split_value[0]
        country_name = split_value[1]
        total_key = "#{country}_#{sku_name}"
        @totals[total_key] = { country_name: country_name, sku_name: sku_name, total_count: 0 } unless @totals[total_key]
        @totals[total_key][:total_count] += total.to_i
      end
    end
    @totals = @totals.sort_by { |_key, value| value[:total_count] }.reverse
    respond_to do |format|
      format.html do
      end
      format.csv do
        send_data to_csv('country_sku_name', @totals), type: 'text/csv; charset=utf-8; header=present',
                                                       disposition: "attachment; filename=sku_name_sales-#{Time.now.strftime('%Y-%m-%d-%H:%M:%S')}.csv"
      end
    end
  end

  # [fixme] move model logic into model
  def country_total
    @totals = {}
    (@start_date..@end_date).each do |date|
      key_pattern = params[:country].present? ? "Country:#{date}:#{params[:country]}*" : "Country:#{date}*"
      keys = REDIS.keys key_pattern
      keys.each do |key|
        value = REDIS.get key
        split_key = key.split ':'
        split_value = value.split ':'
        country = split_key[2]
        currency = split_key[3]
        amount = split_value[0]
        usd_amount = split_value[1]
        total = split_value[2]
        country_name = split_value[3]
        total_key = "#{country}_#{currency}"
        @totals[total_key] ||= { currency: currency,
                                 country_total: 0,
                                 country_total_usd: 0,
                                 country_name: country_name,
                                 total_count: 0,
                                 arpu: 0 }
        @totals[total_key][:country_total] += amount.to_d.truncate(2).to_money(currency)
        @totals[total_key][:country_total_usd] += usd_amount.to_d.truncate(2).to_money
        @totals[total_key][:total_count] += total.to_i
        @totals[total_key][:arpu] = @totals[total_key][:country_total_usd] / @totals[total_key][:total_count]
      end
    end

    @totals = @totals.sort_by { |_key, value| value[:total_count] }.reverse
    @country_total = @totals.map { |_key, total| total[:country_total_usd] }.sum
    @total_count = @totals.map { |_key, value| value[:total_count] }.sum

    respond_to do |format|
      format.html do
      end
      format.csv do
        send_data to_csv('country_total', @totals), type: 'text/csv; charset=utf-8; header=present',
                                                    disposition: "attachment; filename=country_total-#{Time.now.strftime('%Y-%m-%d-%H:%M:%S')}.csv"
      end
    end
  end

  def to_csv(template_name, data_array)
    header = self.class.const_get("#{template_name.upcase}_HEADER")
    CSV.generate do |csv|
      csv << header
      data_array.each do |_key, value|
        csv << value.values_at(*self.class.const_get("#{template_name.upcase}_TEMPLATE"))
      end
    end
  end
end
