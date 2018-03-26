require 'erb'
require_relative 'view/html'
require_relative 'view/plain'
require_relative 'view/json'

module Simpler
  class View

    VIEW_BASE_PATH = 'app/views'.freeze

    def initialize(env)
      @env = env
    end

    def render(binding)
      view_name = to_view_name(content_type)
      view = view_from_string(view_name)

      # duck type viewable
      view.new(@env).render(binding)
    end

    private

    def content_type
      @env['simpler.content_type']
    end

    def view_from_string(view_name)
      view_validate!(view_name)
      Object.const_get(view_name) 
    end

    def view_available?(view_name)
      Object.const_defined?(view_name)
    end

    def view_validate!(view_name)
      raise "Can't render type #{content_type}" unless view_available?(view_name)
    end

    def to_view_name(name)
      "Simpler::View::#{name.capitalize}"
    end
  end
end
