module ApplicationHelper
  def order_time(time)
    [I18n.l(time.to_date), time.strftime('%l:%M %p')].join(' ')
  end
end
