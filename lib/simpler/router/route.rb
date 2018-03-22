module Simpler
  class Router
    class Route

      attr_reader :controller, :action

      def initialize(method, path, controller, action)
        @method = method
        @path = path
        @controller = controller
        @action = action
        @path_pattern = to_path_pattern(path)
        @params_pattern = to_params_pattern(path)
      end

      def match?(method, path)
        @method == method && path.match(@path_pattern)
      end

      def parse_params(path)
        params = path.match(@params_pattern)
        params ? transform_keys(params.named_captures) : {}
      end

      private

      # Available only since Ruby-2.5.0
      # https://ruby-doc.org/core-2.5.0/Hash.html#method-i-transform_keys
      def transform_keys(data)
        _data = {}
        data.each { |key, value| _data[key.to_sym] = value }

        _data
      end

      def to_path_pattern(path)
        Regexp.new("^#{path.gsub(/:([\w_]+)/, '[0-9]+')}$")
      end

      def to_params_pattern(path)
        Regexp.new("^#{path.gsub(/:([\w_]+)/, '(?<\1>[0-9a-z_]+)')}$")
      end
    end
  end
end
