Deface::Override.new(virtual_path: 'spree/admin/products/index',
                     name: 'hide_edit_action_for_qa_role',
                     replace_contents: "[data-hook='admin_products_index_rows'] td:nth-of-type(3)",
                     text:
                         "<% if qa_role %>
                            <%= link_to product.try(:name), '' %>
                          <% else %>
                            <%= link_to product.try(:name), edit_admin_product_path(product) %>
                          <% end %>")
