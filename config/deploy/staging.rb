set :application, 'staging.travelweekly.com.au'
set :stage, :staging
set :log_level, :info

#set remote server details
server 'bambi.was-servers.com', user: 'staging', roles: %w{web app db}

set :ssh_options, {
  keys: %w(~/.ssh/id_rsa)
}

#set remote deploy path
set :deploy_to, -> { "/home/staging" }

fetch(:default_env).merge!(wp_env: :staging)