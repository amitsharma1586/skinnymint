namespace :orders do
  desc 'Sync US AND CA order with innotrac'
  task sync_order_with_innotrac: :environment do
    InnotracSyncWorker.perform_async
  end
end
