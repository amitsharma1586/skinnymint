Deface::Override.new(virtual_path: 'spree/admin/orders/index',
                     name: 'check_with_qa_role_for_delete_action',
                     replace_contents: "[data-hook='admin_orders_index_row_actions']",
                     text:
                       '<% if can? :edit, Spree::Order %>
                          <%= link_to_edit_url edit_admin_order_path(order), title: "admin_edit_#{dom_id(order)}", no_text: true %>
                        <% else %>

                        <% end %>')
