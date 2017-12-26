lock '3.7.1'

set :application, 'sand-and-sky'
set :repo_url, 'git@github.com:Top-Form-Investment/sand-and-sky.git'

ask :branch, proc { `git rev-parse --abbrev-ref HEAD`.chomp }.call

set :linked_files, fetch(:linked_files, []).push('config/database.yml')
set :linked_dirs, fetch(:linked_dirs, []).push('log', 'tmp/pids', 'tmp/cache', 'tmp/sockets', 'vendor/bundle', 'public/system', 'public/spree')
set :default_env, path: '~/.rbenv/shims:~/.rbenv/bin:$PATH'

set :migration_role, :db
set :migration_servers, -> { primary(fetch(:migration_role)) }
# set :assets_roles, [:web, :app]
set :keep_assets, 2
# Defaults to the primary :db server
set :migration_servers, -> { primary(fetch(:migration_role)) }

after 'deploy:publishing', 'deploy:restart'

# namespace :deploy do
#   task :restart do
#     sudo service unicorn restart
#   end
# end
