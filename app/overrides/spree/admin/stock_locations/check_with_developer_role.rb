Deface::Override.new(virtual_path: 'spree/admin/stock_locations/index',
                     name: 'check_with_developer_role',
                     replace_contents: '.actions-2',
                     text:
                         "<% if developer_role %>
                          <%= link_to_edit(stock_location, :no_text => true) %>
                        <% else %>
                          <%= link_to_edit(stock_location, :no_text => true) if can? :create, stock_location %>
                          <%= link_to_delete(stock_location, :no_text => true) if can? :create, stock_location %>
                        <% end %>")
