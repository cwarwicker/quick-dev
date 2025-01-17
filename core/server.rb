require 'sinatra'
require_relative '../scripts/qd.rb'

qd = QuickDev.new()
apps = QuickDev.get_apps()

get '/' do
  @apps = apps
  erb :index
end