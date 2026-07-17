#!/bin/zsh
eval "$(rbenv init - zsh)"

# Build gems inside a Lambda-compatible Linux container
echo "Installing gems via Docker..."
cd app
rm -f Gemfile.lock
docker run --rm \
  --platform linux/amd64 \
  -v "$PWD":/var/task \
  -w /var/task \
  public.ecr.aws/sam/build-ruby3.4:latest-x86_64 \
  /bin/bash -c "bundle config set --local path 'vendor/bundle' && bundle config set --local without 'development' && bundle install"
cd ..
echo "Gems ready."

# Zip
echo "Zipping..."
rm -f app.zip
cd app && zip -r ../app.zip . -x "*.log" > /dev/null && cd ..
echo "Zip ready."

# Deploy
echo "Updating mcp-auth-example-main-sinatra..."
aws lambda update-function-code --function-name mcp-auth-example-main-sinatra --publish --zip-file fileb://app.zip > /dev/null
echo "Done."

echo "Updating mcp-auth-example-gateway-staging..."
aws lambda update-function-code --function-name mcp-auth-example-gateway-staging --publish --zip-file fileb://app.zip > /dev/null
echo "Done."
