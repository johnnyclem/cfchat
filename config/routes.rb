Cfchat::Application.routes.draw do

  match "posts/search_and_filter" => "posts#index", :via => [:get, :post], :as => :search_posts
  resources :posts do
    collection do
      post :batch
      get  :treeview
    end
    member do
      post :treeview_update
    end
  end


  root :to => 'beautiful#dashboard'
  match ':model_sym/select_fields' => 'beautiful#select_fields'

end
