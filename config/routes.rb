Rails.application.routes.draw do
  root 'get_news#index'
  post '/get_news', to: 'get_news#get_news'
  post '/download', to: 'get_news#download'
end
