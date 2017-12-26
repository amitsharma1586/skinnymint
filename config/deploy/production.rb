# ne server(s)
# server '67.205.182.150', user: 'root', roles: %w{web}

# SSH Options
# See the example commented out section in the file
# for more options.

set :user, 'root'
set :deploy_via, :remote_cache
set :use_sudo, true

server '138.197.72.17',
       roles: [:web, :app, :db],
       port: fetch(:port),
       user: fetch(:user),
       primary: true

set :deploy_to, '/home/rails/sand-and-sky'

set :rails_env, :production
set :conditionally_migrate, true
