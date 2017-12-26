// This is a manifest file that'll be compiled into including all the files listed below.
// Add new JavaScript/Coffee code in separate files in this directory and they'll automatically
// be included in the compiled file accessible from http://example.com/assets/application.js
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// the compiled file.
//
//= require jquery
//= require jquery_ujs
//= require moment
//= require bootstrap-datetimepicker
//= require spree/backend
//= require_tree .
//= require spree/backend/spree_multi_currency
//= require spree/backend/spree_paypal_express

$(function () {
	$('.datetimepicker').datetimepicker({format: 'YYYY-MM-DD hh:mm A'}).on('dp.change', function(e) {
	     if (e.oldDate === null) {
	     	var dateNow = new Date();
	        $(this).data('DateTimePicker').date(moment(dateNow).hours(0).minutes(0).seconds(0).milliseconds(0));
	    }
	});

});
//= require spree/backend/spree_reviews
