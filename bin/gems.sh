#!/bin/zsh
eval "$(rbenv init - zsh)"
cd app
rbenv exec bundle lock --add-platform x86_64-linux
rbenv exec bundle config unset --local deployment
rbenv exec bundle config set --local path 'vendor/bundle'
rbenv exec bundle config set --local without development
rbenv exec bundle install
rbenv exec bundle clean
rbenv exec bundle config unset --local path
rbenv exec bundle config unset --local without
rbenv exec bundle install
cd ..
