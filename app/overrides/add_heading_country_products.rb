Deface::Override.new(virtual_path: 'spree/admin/orders/index',
                     insert_after: "erb[loud]:contains('sort_link @search, :number')",
                     text: "<th><%= link_to Spree.t(:country), '#' %> </th>
    <th><%= link_to Spree.t(:products), '#' %> </th>",
                     name: 'add_heading_country_products')
