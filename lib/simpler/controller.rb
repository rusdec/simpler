require_relative 'view'
require 'json'

module Simpler
  class Controller

    attr_reader :name, :request, :response

    CONTENT_TYPES = { html:   'text/html',
                      json:   'text/json',
                      plain:  'text/plain' }

    def initialize(env)
      @name = extract_name
      @request = Rack::Request.new(env)
      @response = Rack::Response.new
    end

    def make_response(action)
      @request.env['simpler.controller'] = self
      @request.env['simpler.action'] = action

      set_default_content_type
      set_default_headers

      send(action)

      write_response

      @response.finish
    end

    private

    attr_accessor :content_type, :content_body

    def extract_name
      self.class.name.match('(?<name>.+)Controller')[:name].downcase
    end

    def write_response
      body = render_body

      set_content_type_header(content_type)
      @response.write(body)
    end

    def set_default_headers
      set_content_type_header(content_type)
    end

    def render_body
      send "render_#{content_type}"
    end

    def params
      @request.params
    end

    def render(data)
      data = parse_render_data(data)

      if data[:type] == :html
        @request.env['simpler.template'] = data
      else
        self.content_type = data[:type]
        self.content_body = data[:body]
      end
    end

    def render_html
      View.new(@request.env).render(binding)
    end

    def render_plain
      content_body
    end

    def render_json
      JSON.generate(content_body)
    end

    def set_default_content_type
      self.content_type = :html
    end

    def set_content_type_header(type)
      @response['Content-Type'] = CONTENT_TYPES[type]
    end

    def parse_render_data(data)
      _data = { body: nil, type: :html }

      if data.is_a?(Hash)
        _data[:type] = data.keys[0]
        _data[:body] = data[_data[:type]]
      else
        _data[:body] = data
      end
      content_type_valid!(_data[:type])

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
