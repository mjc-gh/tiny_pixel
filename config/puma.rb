# Default to development
rails_env = ENV['RAILS_ENV'] || "development"

if rails_env == "development"
    # Specifies the `port` that Puma will listen on to receive requests; default is 3000.
  port ENV.fetch("PORT") { 3000 }

  # No threads
  threads 1, 1

  # Specifies the `environment` that Puma will run in.
  environment rails_env

  # Specifies the `pidfile` that Puma will use.
  pidfile ENV.fetch("PIDFILE") { "tmp/pids/server.pid" }

  # Allow puma to be restarted by `bin/rails restart` command.
  plugin :tmp_restart
else
  max_threads = ENV.fetch("RAILS_MAX_THREADS", 3)
  max_workers = ENV.fetch("PUMA_WORKERS", 2)

  # Change to match your CPU core count
  workers max_workers

  # Min and Max threads per worker
  threads 1, max_threads

  app_dir = File.expand_path("..", __dir__)
  shared_dir = "#{File.expand_path("../..", app_dir)}/shared"

  environment rails_env

  # Set up socket location
  bind "unix://#{shared_dir}/tmp/sockets/puma.sock"

  # Logging
  stdout_redirect "#{shared_dir}/log/puma.stdout.log", "#{shared_dir}/log/puma.stderr.log", true

  # Set master PID and state locations
  pidfile "#{shared_dir}/tmp/pids/puma.pid"
  state_path "#{shared_dir}/tmp/pids/puma.state"
  activate_control_app

  on_worker_boot do
    require "active_record"

    ActiveRecord::Base.connection.disconnect! rescue ActiveRecord::ConnectionNotEstablished
    ActiveRecord::Base.establish_connection(YAML.load_file("#{app_dir}/config/database.yml")[rails_env])
  end
end
