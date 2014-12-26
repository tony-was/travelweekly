#set your app name here - should be the dir where it will be deployed to
set :application, 'travelweekly.dev'
set :dev_application, 'travelweekly.dev'

#set your repo url here
set :repo_url, 'git@github.com:tony-was/travelweekly.git'

set :branch, -> { `git rev-parse --abbrev-ref HEAD`.chomp }

set :deploy_to, -> { "/srv/www/#{fetch(:application)}" }

set :log_level, :debug

set :pty, true

set :linked_files, fetch(:linked_files, []).push('.env', 'web/.htaccess')
#set :linked_files, fetch(:linked_files, []).push('.env')
set :linked_dirs, fetch(:linked_dirs, []).push('web/app/uploads')

require 'dotenv'
Dotenv.load

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

set :base_db_filename, -> {"#{fetch(:application)}-#{Time.now.getutc.to_i}.sql"}
set :wpcli_remote_db_file, -> {"#{fetch(:tmp_dir)}/#{fetch(:base_db_filename)}"}
set :wpcli_local_db_file, -> {"/tmp/#{fetch(:base_db_filename)}"}
set :vagrant_root, -> {"../../bedrock-ansible"}
namespace :migrate do
  namespace :pull do
    desc "Downloads both remote database & syncs remote files into Vagrant"
    task :all => ["pull:db", "pull:files"]
    desc "Downloads remote database into Vagrant"
    task :db do
      on roles(:web) do
        within release_path do
          execute :wp, :db, :export, "- |", :gzip, ">", "#{fetch(:wpcli_remote_db_file)}.gz"
          download! "#{fetch(:wpcli_remote_db_file)}.gz", "#{fetch(:wpcli_local_db_file)}.gz"
          execute :rm, "#{fetch(:wpcli_remote_db_file)}.gz"
          run_locally do
            execute :gunzip, "#{fetch(:wpcli_local_db_file)}.gz"
            within fetch(:vagrant_root) do
              execute :vagrant, :up
              execute "ssh -i ~/.vagrant.d/insecure_private_key vagrant@#{fetch(:dev_application)} 'mysql -u#{ENV['DB_USER']} -p#{ENV['DB_PASSWORD']} #{ENV['DB_NAME']}' < #{fetch(:wpcli_local_db_file)}"
              execute "ssh -i ~/.vagrant.d/insecure_private_key vagrant@#{fetch(:dev_application)} 'cd /srv/www/#{fetch(:dev_application)}/current && wp search-replace #{fetch(:application)} #{fetch(:dev_application)}'"
            end
            execute "rm #{fetch(:wpcli_local_db_file)}"
          end
        end
      end
    end
    task :files do
      on roles(:web) do
        within shared_path do
          system("rsync -a --del -L -K -vv --progress --rsh='ssh -p 22' #{fetch(:user)}@#{fetch(:application)}:#{shared_path}/web/app/uploads ./web/app")
        end
      end
    end
  end
end