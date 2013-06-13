require './mini-rails'

require 'pp'

class TestApp < MiniRails::Application
end

TestApp.routes.draw do
  root to: "pages#index"

  match '/time' => "pages#time"
  match '/date' => "pages#date"
  match '/rand' => "pages#rand"

  match 'env' => lambda { |env| [200, {}, [PP.pp(env, "")]] }
end

class PagesController < MiniRails::Controller
  def index
    render text: "Hello, world!"
  end

  def time
    render :time
  end

  # implicit render
  def date
  end

  # rand will render even though we haven't defined the action
  # def rand
  # end
end

run TestApp.new
