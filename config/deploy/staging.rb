#set unique application name for staging and production to avoid permission problems when running deploy:check
set :application, 'staging.travelweekly.com.au'

#set remote deploy path
set :deploy_to, -> { "/home/staging-travelweekly" }

#set remote server details
server '54.66.251.172', user: 'staging-travelweekly', roles: %w{web app db}

set :stage, :staging
set :log_level, :info
set :ssh_options, {
  keys: %w(~/.ssh/id_rsa)
}

fetch(:default_env).merge!(wp_env: :staging)