$(document).ready(function() {

  getCountryId = function(region) {
    return $('#' + region + 'country select').val();
  };

  fillCities = function(country_code, cityId) {
    $.ajax({
      url: "/fetch_cities_from_aramex",
      type: 'GET',
      dataType: "json",
      data: {
        country_code: country_code
      },
      success: function(data) {
        $(cityId).autocomplete({
          source: data,
        });
      },
      error: function() {
      }
    });
  }

  getCountry = function(region) {
    countryId = getCountryId(region);
    if (countryId != null) {
      if (region == 'b') {
        cityId = '#order_bill_address_attributes_city'
        countryInputId = "#order_bill_address_attributes_country_id"
      }
      else {
        cityId = '#order_ship_address_attributes_city'
        countryInputId = "#order_ship_address_attributes_country_id"
      }
      fillCities($(countryInputId).val(), cityId)
    }
  }

  $('#bcountry select').change(function() {
    getCountry('b')
  });

  $('#scountry select').change(function() {
    getCountry('s')
  });

  getCountry('b');
  getCountry('s');
})