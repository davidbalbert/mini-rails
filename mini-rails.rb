require 'erb'

module MiniRails
  class Application
    class << self
      def routes
        @routes ||= RouteSet.new
      end
    end

    def initialize
      @routes = self.class.routes
    end

    def call(env)
      path = env["PATH_INFO"]
      if @routes.has_route?(path)
        @routes[path].call(env)
      else
        [404, {}, ["Not found!"]]
      end
    end
  end

  class RouteSet
    def initialize
      @routes = {}
    end

    def draw(&block)
      instance_eval(&block)
    end

    def has_route?(path)
      @routes.has_key?(path)
    end

    def [](path)
      @routes[path]
    end

    private
    def root(to: raise("must pass `to'"))
      @routes['/'] = controller_action_to_proc(to)
    end

    def match(args)
      path, controller_action = args.to_a.first
      path = '/' + path unless path.start_with?('/')

      @routes[path] = controller_action_to_proc(controller_action)
    end

    def controller_action_to_proc(controller_action)
      if controller_action.is_a?(String)
        controller_name, action_name = controller_action.split("#")

        controller_class_name = "#{constantize(controller_name)}Controller"

        lambda { |env|
          Object.const_get(controller_class_name).new.action(action_name.intern).call(env)
        }
      else
        controller_action
      end
    end

    def constantize(string)
      string.split("_").map(&:capitalize).join
    end
  end

  class Controller
    def action(name)
      lambda { |env|
        if respond_to?(name)
          send(name)

          unless @body
            render name
          end
        elsif template_exists?(name)
          render name
        else
          raise NoMethodError, "#{self.class} does not respond to `#{name}`"
        end


        [200, {}, @body]
      }
    end

    def render(template=nil, text: nil)
      if text
        @body = [text]
      elsif template
        @body = [ERB.new(File.read(template_name(template))).result]
      else
        raise "you must specify something to render"
      end
    end

    private
    def template_exists?(name)
      File.exists?(template_name(name))
    end

    def template_name(name)
      "#{name}.html.erb"
    end
  end
end

