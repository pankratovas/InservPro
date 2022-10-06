Rails.application.routes.draw do
  scope '/inservpro' do

    devise_for :users
    resources :users
    resources :roles, except: :show
    resources :reports, only: [:show] do
      match 'drop_list', to: 'reports#drop_list', via: 'get'
      match 'drop_callback_action', to: 'reports#drop_callback_action', via: 'get'
      match 'realtime_statistics', to: 'reports#realtime_statistics', via: 'get'
    end

    devise_scope :user do
      root to: 'devise/sessions#new'
    end

  end
end
