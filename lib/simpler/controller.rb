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

    attr_accessor :content_type, :content_body

    def extract_name
      self.class.name.match('(?<name>.+)Controller')[:name].downcase
    end

    def write_response
      body = render_body

      @response.write(body)
    end

    def set_default_headers
      set_default_content_type
    end

    def render(data)
      data = parse_render_data(data)

      if data[:type] == :html
        @request.env['simpler.template'] = data[:body]
      else
        self.content_body = data[:body]
      end

      set_content_type(data[:type])
    end

    def render_body
      send "render_body_#{content_type}"
    end

    def render_body_html
      View.new(@request.env).render(binding)
    end

    def render_body_plain
      content_body
    end

    def render_body_json
      JSON.generate(content_body)
    end

    def set_content_type(type)
      self.content_type = type
      set_content_type_header(type)
    end

    def set_default_content_type
      set_content_type(:html)
    end

    def set_content_type_header(type)
      content_type_valid!(type)
      @response['Content-Type'] = CONTENT_TYPES[type]
    end

    def set_status(status_code)
      @response.status = status_code
    end

    def parse_render_data(data)
      _data = { body: nil, type: :html }

      if data.is_a?(Hash)
        _data[:type] = data.keys[0]
        _data[:body] = data[_data[:type]]
      else
        _data[:body] = data
      end

      _data
    end

    def content_type_valid!(type)
      controller_action = "#{self.class.name}##{@request.env['simpler.action']}"
      raise "Unknown content type `#{type}` \
             in #{controller_action}" unless content_type_valid?(type)
    end

    def content_type_valid?(type)
      CONTENT_TYPES.has_key?(type)
    end
  end
end
