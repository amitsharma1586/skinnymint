source 'https://rubygems.org'
ruby '2.2.1'


# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 4.2.0'
# Use postgresql as the database for Active Record
gem 'pg', '~> 0.15'
# Use SCSS for stylesheets
gem 'sass-rails', '~> 5.0'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'
# Use CoffeeScript for .coffee assets and views
gem 'coffee-rails', '~> 4.1.0'
# See https://gitaphub.com/rails/execjs#readme for more supported runtimes
# gem 'therubyracer', platforms: :ruby

# Use jquery as the JavaScript library
gem 'jquery-rails'
# Turbolinks makes following links in your web application faster. Read more: https://github.com/rails/turbolinks
gem 'turbolinks'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.0'
# bundle exec rake doc:rails generates the API under doc/api.
gem 'bootstrap3-datetimepicker-rails', '~> 4.17.42'
gem 'exception_notification'
gem 'momentjs-rails', '>= 2.9.0'
gem 'sdoc', '~> 0.4.0', group: :doc
gem 'sidekiq'
gem 'sidekiq_mailer'
gem 'therubyracer'


# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use Unicorn as the app server
group :production do
  gem 'newrelic_rpm'
  gem 'unicorn'
end

# Use Capistrano for deployment
gem 'capistrano-rails', group: :development
gem 'capistrano-rvm', group: :development

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug'
  gem 'rubocop', '~> 0.47.0', require: false
end


group :development do
  # Access an IRB console on exception pages or by using <%= console %> in views
  gem 'web-console', '~> 2.0'

  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
end


## configuration related gem ##
gem 'config'
gem 'easypost'
gem 'prawn'
gem 'redis'
gem 'rest-client'


## schedule job
gem 'sidekiq-cron', '~> 0.4.0'

### related to spree ##
gem 'spree', github: 'spree/spree', branch: '3-0-stable'
gem 'spree_auth_devise', github: 'spree/spree_auth_devise', branch: '3-0-stable'
gem 'spree_editor', github: 'spree-contrib/spree_editor', branch: '3-0-stable'
gem 'spree_gateway', github: 'spree/spree_gateway', branch: '3-0-stable'
gem 'spree_mail_settings', github: 'spree-contrib/spree_mail_settings', branch: '3-0-stable'
gem 'spree_multi_currency', github: 'spree/spree_multi_currency', branch: '3-0-stable'
gem 'spree_paypal_express', github: 'spree-contrib/better_spree_paypal_express', branch: '3-0-stable'
gem 'spree_reviews', github: 'spree-contrib/spree_reviews', branch: '3-0-stable'
gem 'spree_static_content', github: 'spree-contrib/spree_static_content', branch: '3-0-stable'
gem 'spree_stock_notifications', github: 'joshnuss/spree_stock_notifications', branch: '3-0-stable'
