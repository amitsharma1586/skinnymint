Deface::Override.new(virtual_path: 'spree/admin/orders/index',
                     insert_after: "erb[loud]:contains('order.display_total.to_html')",
                     text: "<td><% order.payments.valid.each do |payment| %>
    <%= payment.payment_method.name %>
    <%end%> </td>",
                     name: 'add_data_payment_method')
