require 'csv'
# Order reports
class UnfulfilledOrdersReporter
  EMPTY_ROW = [%w()].freeze
  ORDER_TEMPLATE = {
    0  => '#completed_at',
    1  => '#number',
    2  => '#ship_address.country.iso',
    3  => '#considered_risky',
    4  => '#state',
    5  => '#payment_state',
    6  => '#shipment_state',
    7  => '#email',
    8  => '#total',
    9  => '#payment_method_type'
  }.freeze
  UNFULFILLED_TEMPLATE = {
    0  => '#completed_at',
    1  => '#number',
    2  => '#ship_address.country.iso',
    3  => '#considered_risky',
    4  => '#state',
    5  => '#payment_state',
    6  => '#shipment_state',
    7  => '#email',
    8  => '#total',
    9  => '#payment_method_type'
  }.freeze
  ORDER_HEADER = %w(
    completed_at number country risky state payment_state shipment_state cutsomer_email total payment_method
  ).freeze
  UNFULFILLED_HEADER = %w(
    completed_at number country risky state payment_state shipment_state cutsomer_email total payment_method
  ).freeze

  def initialize(orders, options = {})
    @orders = options[:template_name] == 'order' ? orders : orders.unfulfilled
    @template_name = options[:template_name]
  end

  def template
    @template ||= self.class.const_get("#{@template_name.upcase}_TEMPLATE")
  end

  def number_of_columns
    header.length
  end

  def header
    @header ||= self.class.const_get("#{@template_name.upcase}_HEADER")
  end

  def row(order)
    build_row order, template, number_of_columns
  end

  def rows
    @rows ||= @orders.map do |order|
      row order
    end
  end

  def build_row(model, template, size)
    cells = Array.new size, nil
    cells.each_with_index do |_v, i|
      next if template[i].blank?
      cells[i] = if template[i].start_with?('#')
                   begin
                     model.send_chain(template[i][1..-1])
                   rescue
                     'This order doesnt have all details. Please contact cynthia.kuang@skinnymint.com.'
                   end
                 else
                   template[i]
                 end
    end
    cells
  end

  def to_csv
    CSV.generate(force_quotes: true) do |csv|
      csv << header
      rows.each do |row|
        csv << row
      end
    end
  end
end
