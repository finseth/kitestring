Kitestring::Application.routes.draw do
  root to: 'home#index'
  get '/terms' => 'home#terms'
  get '/privacy' => 'home#privacy'
  get '/faq' => 'home#faq'
  get '/home' => 'home#home'

  post '/sign_up_validate' => 'home#sign_up_validate'
  post '/sign_up' => 'home#sign_up'
  post '/new_user' => 'home#new_user'

  post '/sign_in' => 'home#sign_in'
  post '/sign_out' => 'home#sign_out'

  post '/new_contact' => 'home#new_contact'
  post '/delete_contact/:id' => 'home#delete_contact'
  post '/move_contact_up/:id' => 'home#move_contact_up'
  post '/move_contact_down/:id' => 'home#move_contact_down'
  post '/checkpoint' => 'home#checkpoint'
  post '/end_checkpoint' => 'home#end_checkpoint'
  post '/status' => 'home#status'

  post '/update_name' => 'home#update_name'
  post '/update_password' => 'home#update_password'
  post '/delete_account' => 'home#delete_account'

  get 'update' => 'home#update'
  post 'twilio' => 'home#twilio'
  
  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

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
end
