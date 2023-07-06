Rails.application.routes.draw do
  get '/intraday', to: 'home#intraday', as: 'intraday'
  get '/daily', to: 'home#daily', as: 'daily'
  get '/weekly', to: 'home#weekly', as: 'weekly'
  get '/monthly', to: 'home#monthly', as: 'monthly'
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  # root "articles#index"
  root "home#intraday"
end
