require './mini-rails'

require 'pp'

class TestApp < MiniRails::Application
  draw_routes do
    root to: "pages#index"

    match '/foo' => "pages#foo"

    match 'env' => lambda { |env| [200, {}, [PP.pp(env, "")]] }
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

run TestApp.new
