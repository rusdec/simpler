require_relative 'view'
require 'json'

module Simpler
  class Controller

    attr_reader :name, :request, :response

    CONTENT_TYPES = { html:   'text/html',
                      json:   'text/json',
                      plain:  'text/plain',
                      xml:    'application/xml' }.freeze

    def initialize(env)
      @name = extract_name
      @request = Rack::Request.new(env)
      @response = Rack::Response.new
      @params = env['simpler.controller.params']
    end

    def make_response(action)
      @request.env['simpler.controller'] = self
      @request.env['simpler.action'] = action

      set_default_headers

      send(action)

      write_response

      @response.finish
    end

    def params
      @request.params.merge(@params)
    end

    private

    def write_response
      body = render_body
      @response.write(body)
    end

    def set_default_headers
      set_content_type_header(:html)
    end

    def render(data)
      data = parse_render_data(data)
      set_content_type_header(data[:type])
      @request.env['simpler.template'] = data[:body]
    end

    def render_body
      View.new(@request.env).render(binding)
    end

    def set_content_type_header(type)
      content_type_valid!(type)
      # response is not available in View
      @response['Content-Type'] = CONTENT_TYPES[type]
      # content type forwarding to view
      # env is available in View
      @request.env['simpler.content_type'] = type
    end

    def set_status(status_code)
      @response.status = status_code
    end

    def parse_render_data(data)
      parsed_data = { body: nil, type: :html }

      if data.is_a?(Hash)
        parsed_data[:type] = data.keys[0]
        parsed_data[:body] = data[parsed_data[:type]]
      else
        parsed_data[:body] = data
      end

      parsed_data
    end

    def content_type_valid!(type)
      controller_action = "#{self.class.name}##{@request.env['simpler.action']}"
      raise "Unknown content type `#{type}` \
             in #{controller_action}" unless content_type_valid?(type)
    end

    def content_type_valid?(type)
      CONTENT_TYPES.has_key?(type)
    end

    def extract_name
      self.class.name.match('(?<name>.+)Controller')[:name].downcase
    end
  end
end
