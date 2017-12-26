namespace :unicorn do
  task :start do
    on roles(:app) do
      execute :service, 'unicorn start'
    end
  end

  task :restart do
    on roles(:app) do
      execute :service, 'unicorn restart'
    end
  end
end

namespace :nginx do
  task :start do
    on roles(:app) do
      execute :service, 'nginx start'
    end
  end

  task :restart do
    on roles(:app) do
      execute :service, 'nginx restart'
    end
  end
end
