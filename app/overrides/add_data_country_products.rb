Deface::Override.new(virtual_path: 'spree/admin/orders/index',
                     insert_after: "erb[loud]:contains('link_to order.number')",
                     text: "<td><%= order.ship_address.country.iso_name rescue '' %> </td>
    <td><%= order.item_skus %> </td>",
                     name: 'add_data_country_products')
