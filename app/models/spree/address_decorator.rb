Spree::Address.class_eval do
  include Spree::Shipments::AramexAddressValidator

  # validations
  validate :aramex_address_validation

  # Validate address for aramex shipping
  def aramex_address_validation
    zones = Spree::ShippingMethod.where(['LOWER(admin_name) like ?', '%aramex%']).map(&:zones).flatten
    if zones.map(&:countries).flatten.map(&:iso).include?(country.iso)
      response = JSON.parse(validate_address(city, zipcode, country.iso))
      if response['HasErrors'] == true && errors[:zipcode].blank?
        if response['SuggestedAddresses'].present?
          errors.add(:base, response['Notifications'].map { |data| data['Message'] }.join(', ') + ', Suggested city name is - ' + response['SuggestedAddresses'].map { |data| data['City'] }.join(', '))
        else
          cities_response = JSON.parse(fetch_cities(country.iso, city[0..1]))
          errors.add(:base, cities_response['Notifications'].map { |data| data['Message'] }.join(', ') + ', Suggested city name is - ' + cities_response['Cities'].join(' ,'))
        end
      end
    end
  rescue
    return true
  end
end
