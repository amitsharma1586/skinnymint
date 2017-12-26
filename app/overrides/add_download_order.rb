Deface::Override.new(virtual_path: 'spree/admin/orders/index',
                     insert_before: "erb[silent]:contains('page_actions')",
                     text: "
	<%= button_link_to Spree.t(:upload_fulfilled), upload_fulfilled_admin_orders_path, class: 'btn-success'%> <br><br>
	<%= button_link_to Spree.t(:download_order), admin_orders_path(params.merge(template_name: 'order', format: 'csv')), class: 'btn-success', icon: 'download', id: 'admin_unfulfilled_download' %>
	<%= button_link_to Spree.t(:download_unfulfilled), admin_orders_path(params.merge(template_name: 'unfulfilled', format: 'csv')), class: 'btn-success', icon: 'download', id: 'admin_unfulfilled_download' %>
	",
                     name: 'add_download_order')
