require 'rest-client'
module Spree
  module Shipments
    # Validate the address from aramex api
    module AramexAddressValidator
      # validate address
      def validate_address(city, zip_code, country_iso)
        url = Settings['aramex_addr_validation']['url']
        params = { Address:
                    { Line1: '', Line2: '', Line3: '', City: city, PostCode: zip_code, CountryCode: country_iso },
                   ClientInfo:
                    { AccountCountryCode: Settings['aramex_addr_validation']['country_code'],
                      AccountEntity: Settings['aramex_addr_validation']['account_entity'],
                      AccountNumber: Settings['aramex_addr_validation']['account_number'],
                      AccountPin: Settings['aramex_addr_validation']['account_pin'],
                      UserName: ENV['ARAMEX_API_USER_NAME'],
                      Password: ENV['ARAMEX_API_PASSWORD'],
                      Version: 'v1',
                      Source: 24 },
                   Transaction:
                    { Reference1: '001', Reference2: '002', Reference3: '003', Reference4: '004', Reference5: '005' } }.to_json
        RestClient.post url, params, content_type: :json, accept: :json
      end

      # fetch cities based on country
      def fetch_cities(country_iso, city = '')
        url = Settings['aramex_addr_validation']['city_fetch_url']
        params = { ClientInfo:
                    { AccountCountryCode: Settings['aramex_addr_validation']['country_code'],
                      AccountEntity: Settings['aramex_addr_validation']['account_entity'],
                      AccountNumber: Settings['aramex_addr_validation']['account_number'],
                      AccountPin: Settings['aramex_addr_validation']['account_pin'],
                      UserName: ENV['ARAMEX_API_USER_NAME'],
                      Password: ENV['ARAMEX_API_PASSWORD'],
                      Version: 'v1', Source: 24 },
                   CountryCode: country_iso,
                   NameStartsWith: city,
                   State: '',
                   Transaction:
                        { Reference1: '001', Reference2: '002', Reference3: '003', Reference4: '004', Reference5: '005' } }.to_json
        RestClient.post url, params, content_type: :json, accept: :json
      end
    end
  end
end
