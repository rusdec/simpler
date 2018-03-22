require 'logger'

module Middleware
  class AppLogger

    def initialize(app)
      @logger = Logger.new(Simpler.root.join('log/app.log'))
      @app = app
    end

    def call(env)
      status, headers, body = @app.call(env)

      log_data(env, status, headers)

      [status, headers, body]
    end
    
    private

    def log_data(env, status, headers)
      data = {}
      data[:request] = [env['REQUEST_METHOD'], env['REQUEST_URI']]

      if env['simpler.controller']
        controller = env['simpler.controller']
        data[:handler] = ["#{controller.class}##{env['simpler.action']}"]
        data[:parametres] = [controller.params]
      end

      data[:response] = [status, "[#{headers['Content-Type']}]"]
      data[:response] << "#{env['simpler.template']}.html.erb" if env['simpler.template']

      @logger.info(data_to_text(data))
    end

    def data_to_text(data)
      data.collect { |title, text| "\n#{title.capitalize}: #{text.join(' ')}" }.join('')
    end
  end
end
