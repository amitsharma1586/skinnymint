Deface::Override.new(virtual_path: 'spree/admin/orders/index',
                     insert_after: "erb[loud]:contains('sort_link @search, :total')",
                     text: "<th><%= link_to Spree.t(:payment_method), '#' %> </th>",
                     name: 'add_heading_payment')
