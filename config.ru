module MiniRails
  class Application
    class << self
      attr_reader :routes

      def draw_routes(&block)
        @routes = RouteSet.new(&block).to_h
      end
    end

    def initialize
      @routes = self.class.routes
    end

    def call(env)
      path = env["PATH_INFO"]
      if @routes.has_key?(path)
        @routes[path].call(env)
      else
        [404, {}, ["Not found!"]]
      end
    end
  end

  class RouteSet
    def initialize(&block)
      @routes = {}
      instance_eval(&block)
    end

    def to_h
      @routes
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
          Object.const_get(controller_class_name).action(action_name.intern).call(env)
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
    def self.action(name)
      lambda { |env|
        controller = new(env)
        controller.send(name)

        [200, {}, controller.body]
      }
    end

    attr_reader :body

    def initialize(env)
      @env = env
    end

    def render(text: raise("supply some text"))
      @body = [text]
    end
  end
end

require 'pp'

module TestApp
  class Application < MiniRails::Application
    draw_routes do
      root to: "pages#index"

      match '/foo' => "pages#foo"

      match 'env' => lambda { |env| [200, {}, [PP.pp(env, "")]] }
    end
  end
end

class PagesController < MiniRails::Controller
  def index
    render text: "Hello, world!"
  end

  def foo
    render text: "Hello, foo!"
  end
end

run TestApp::Application.new
