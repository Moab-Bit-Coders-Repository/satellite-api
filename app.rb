require "eventmachine"
require 'thin'
require_relative 'main'

def run(opts)
  EM.run do
    server  = opts[:server] || 'thin'
    host    = opts[:host]   || '0.0.0.0'
    port    = opts[:port]   || '9292'
    app     = opts[:app]

    # Start the web server. Note that you are free to run other tasks
    # within your EM instance.
    Rack::Server.start({
      app:    app,
      server: server,
      Host:   host,
      Port:   port,
      signals: false,
    })
    
    sinatra_instance(app).start_transmitter
    sinatra_instance(app).start_stayin_alive
  end
end

def sinatra_instance(app)
  app.instance_variable_get :@instance
end

run app: Ionosphere.new
