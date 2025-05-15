# frozen_string_literal: true

DfcProvider::Engine.routes.draw do
  resources :addresses, only: [:show]
  resources :enterprises, only: [:show] do
    resources :catalog_items, only: [:index, :show, :update]
    resources :offers, only: [:show, :update]
    resources :scopes, only: [:show, :destroy] do
      # Rails maps the collection path to the create action.
      # But we want a member path according to the spec.
      # POST /enterprises/10000/scopes                # Rails default create.
      # POST /enterprises/10000/scopes/ReadEnterprise # Specified here.
      post "", on: :member, to: "scopes#create"
    end
    resources :supplied_products, only: [:create, :show, :update]
    resources :social_medias, only: [:show]
  end
  resources :enterprise_groups, only: [:index, :show] do
    resources :affiliated_by, only: [:create, :destroy], module: 'enterprise_groups'
  end
  resources :persons, only: [:show]
  resources :product_groups, only: [:show]

  resource :affiliate_sales_data, only: [:show]
end
