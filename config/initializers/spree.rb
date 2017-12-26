# Configure Spree Preferences
#
# Note: Initializing preferences available within the Admin will overwrite any changes that were made through the user interface when you restart.
#       If you would like users to be able to update a setting with the Admin it should NOT be set here.
#
# Note: If a preference is set here it will be stored within the cache & database upon initialization.
#       Just removing an entry from this initializer will not make the preference value go away.
#       Instead you must either set a new value or remove entry, clear cache, and remove database entry.
#
# In order to initialize a setting do:
# config.setting_name = 'new value'
Spree.config do |config|
  # Example:
  # Uncomment to stop tracking inventory levels in the application
  config.track_inventory_levels = true
  config.stock_notifications_list = Settings.low_stock_notifies_emails
  # when stock level reaches the "low stock threshold", admins will be notified. Default is 1
  config.low_stock_threshold = 2
end

# Spree::Image.attachment_definitions[:attachment][:url] = 'http://test.sandandsky.com/system/:class/:attachment/:id_partition/:style/'
# Spree::Image.attachment_definitions[:attachment][:path] = '/home/rails/sand-and-sky/shared/system/:class/:attachment/:id_partition/:style/'
# Spree::Config[:attachment_url] = 'http://test.sandandsky.com/system/:class/:attachment/:id_partition/:style/:hash.:extension'
Spree.user_class = 'Spree::LegacyUser'
Spree::Shipment.whitelisted_ransackable_attributes = %w(number tracking)
Spree::Address.whitelisted_ransackable_associations = %w(country)
Spree::Address.whitelisted_ransackable_attributes = %w(firstname lastname company country_id)
Spree::Country.whitelisted_ransackable_associations = %w(zones)
Spree::Country.whitelisted_ransackable_attributes = %w(id iso)
Spree::Zone.whitelisted_ransackable_attributes = %w(id name)
