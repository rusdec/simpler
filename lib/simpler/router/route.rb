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
      end

      def match?(method, path)
        @method == method && path.match(@path_pattern)
      end

      def parse_params(path)
        path.match(@path_pattern)
      end

      private

      def to_path_pattern(path)
        Regexp.new("^#{path.gsub(/:([\w_]+)/, '(?<\1>[0-9a-z_]+)')}$")
      end
    end
  end
end
