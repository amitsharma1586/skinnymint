Deface::Override.new(virtual_path: 'spree/admin/users/index',
                     name: 'check_with_qa_role_for_delete_action',
                     replace_contents: "[data-hook='admin_users_index_row_actions']",
                     text:
                         "<%= link_to_edit user, no_text: true if !qa_role %>
                          <%= link_to_delete user, no_text: true if !qa_role %>")
