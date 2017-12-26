namespace :deploy do
  task :restart do
    sudo service unicorn restart
  end
end
