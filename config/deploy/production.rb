set :stage, :production
set :log_level, :info

#set remote server details
server 'server.url.or.ip', user: 'user', roles: %w{web app db}

set :ssh_options, {
  keys: %w(~/.ssh/id_rsa)
}

#set remote deploy path
set :deploy_to, -> { "/var/www/application" }

fetch(:default_env).merge!(wp_env: :production)