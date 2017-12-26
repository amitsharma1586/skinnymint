Deface::Override.new(virtual_path: 'spree/admin/users/index',
                     name: 'check_with_qa_role',
                     replace_contents: '.user_email',
                     text:
                         "<% if qa_role %>
                            <%= link_to user.email,''%>
                          <% else %>
                            <%= link_to user.email, edit_admin_user_url(user) %>
                          <% end %>")
