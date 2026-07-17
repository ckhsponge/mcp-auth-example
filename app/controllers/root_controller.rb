class RootController < ApplicationController

  get '/' do
    slim :index
  end

  get '/test' do
    h = { foo: 'bar' }.with_indifferent_access
    year = 1.year
    content_type :json
    { indifferent_access: h['foo'], one_year_seconds: year }.to_json
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
