Rails.application.routes.draw do
  get 'home/dashboard'
  get '/daily', to: 'home#daily', as: 'daily'
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  # root "articles#index"
  root "home#index"
end
