#set your app name here - should be the dir where it will be deployed to
set :application, 'travelweekly.dev'

#set your repo url here
set :repo_url, 'git@github.com:tony-was/travelweekly.git'

set :branch, -> { `git rev-parse --abbrev-ref HEAD`.chomp }

set :deploy_to, -> { "/srv/www/#{fetch(:application)}" }

set :log_level, :debug

set :pty, true

set :linked_files, fetch(:linked_files, []).push('.env', 'web/.htaccess')
#set :linked_files, fetch(:linked_files, []).push('.env')
set :linked_dirs, fetch(:linked_dirs, []).push('web/app/uploads')

namespace :deploy do
  desc 'Restart application'
  task :restart do
    on roles(:app) do
      sudo 'service', 'nginx', 'reload'
    end
  end
end

#after 'deploy:publishing', 'deploy:restart'

namespace :deploy do
  desc 'Update WordPress template root paths to point to the new release'
  task :update_option_paths do
    on roles(:app) do
      within fetch(:release_path) do
        if test :wp, :core, 'is-installed'
          [:stylesheet_root, :template_root].each do |option|
            # Only change the value if it's an absolute path
            # i.e. The relative path "/themes" must remain unchanged
            # Also, the option might not be set, in which case we leave it like that
            value = capture :wp, :option, :get, option, raise_on_non_zero_exit: false
            if value != '' && value != '/themes'
              execute :wp, :option, :set, option, fetch(:release_path).join('web/wp/wp-content/themes')
            end
          end
        end
      end
    end
  end
end

#after 'deploy:publishing', 'deploy:update_option_paths'

namespace :npm do
  desc 'Install npm'
  task :install do
    on roles(:app) do
        within fetch(:release_path).join('web/app/themes/roots') do
            execute 'npm', 'install'
        end
    end
  end
end

after 'deploy:publishing', 'npm:install'

namespace :composer do
  desc 'Composer update'
  task :update do
    on roles(:app) do
        within release_path do
            execute 'composer', 'update'
        end
    end
  end
end

after 'deploy:publishing', 'composer:update'

namespace :grunt do
  desc 'Grunt build'
  task :build do
    on roles(:app) do
        within fetch(:release_path).join('web/app/themes/roots') do
            execute 'grunt', 'build'
        end
    end
  end
end

after 'deploy:publishing', 'grunt:build'