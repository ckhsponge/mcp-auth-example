class RootController < ApplicationController

  get '/' do
    slim :index
  end

  get '/login' do
    sign_in(User.find('1'))
    redirect '/'
  end

  post '/logout' do
    sign_out
    redirect '/'
  end

end
