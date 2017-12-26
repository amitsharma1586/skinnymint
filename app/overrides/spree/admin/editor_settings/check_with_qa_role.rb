Deface::Override.new(virtual_path: 'spree/admin/editor_settings/edit',
                     name: 'check_with_qa_role',
                     replace_contents: '.form-actions',
                     text:
                         "<% if qa_role %>
                          <button class='btn btn-primary' type='submit' name='button' disabled='true'>
                            <span class='icon icon-update'></span>
                             Update
                          </button>
                        <% else %>
                         <%= button Spree.t('actions.update'), 'update' %>
                        <% end %>")
