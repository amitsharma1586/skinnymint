task :restart_sidekiq do
  on roles(:worker) do
    execute :service, 'sidekiq restart'
  end
end
