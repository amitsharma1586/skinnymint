Rails.application.routes.draw do
  mount Ckeditor::Engine => '/ckeditor'
  # This line mounts Spree's routes at the root of your application.
  # This means, any requests to URLs such as /products, will go to Spree::ProductsController.
  # If you would like to change where this engine is mounted, simply change the :at option to something different.
  #
  constraint = ->(request) { request.env['warden'].authenticate? && request.env['warden'].user.admin? }
  constraints constraint do
    mount Sidekiq::Web => '/sidekiq'
  end
  # We ask that you don't use the :as option here, as Spree relies on it being the default of "spree"
  mount Spree::Core::Engine, at: '/'
  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  Spree::Core::Engine.add_routes do
    namespace :admin do
      resources :orders do
        collection do
          get 'upload_fulfilled'
          post 'upload_fulfilled'
          post 'confirm_fulfilled'
        end
      end
    end
  end
  # You can have the root of your site routed with "root"
  # root 'welcome#index'

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  Spree::Core::Engine.add_routes do
    namespace :admin do
      resources :reports, only: [:index] do
        collection do
          get :country_total
          post :country_total
          get :country_sku_total
          post :country_sku_total
          get :country_sku_name
          post :country_sku_name
        end
      end
    end
    get 'fetch_cities_from_aramex', to: 'checkout#fetch_cities_from_aramex'
  end
  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
  Spree::Core::Engine.add_routes do
    namespace :api do
      scope :easypost_hooks do
        post 'receive_webhook', to: 'web_hooks#receive_webhook'
      end
    end
  end
end
