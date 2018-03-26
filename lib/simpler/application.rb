require 'yaml'
require 'singleton'
require 'sequel'
require_relative 'router'
require_relative 'controller'

module Simpler
  class Application

    include Singleton

    attr_reader :db

    def initialize
      @router = Router.new
      @db = nil
      @response = Rack::Response.new
    end

    def bootstrap!
      require_logger
      setup_database
      require_app
      require_routes
    end

    def routes(&block)
      @router.instance_eval(&block)
    end

    def call(env)
      route = @router.route_for(env)
      if route
        env['simpler.controller.params'] = route.parse_params(env['PATH_INFO'])
        controller = route.controller.new(env)
        action = route.action

        make_response(controller, action)
      else
        route_not_found
      end
    end

    protected

    attr_accessor :response

    private

    def require_app
      Dir["#{Simpler.root}/app/**/*.rb"].each { |file| require file }
    end

    def require_routes
      require Simpler.root.join('config/routes')
    end

    def require_logger
      require Simpler.root.join('middleware/app_logger')
    end

    def setup_database
      database_config = YAML.load_file(Simpler.root.join('config/database.yml'))
      database_config['database'] = Simpler.root.join(database_config['database'])
      @db = Sequel.connect(database_config)
    end

    def make_response(controller, action)
      controller.make_response(action)
    end

    def route_not_found
      self.response.status = 404
      response
    end
  end
end
