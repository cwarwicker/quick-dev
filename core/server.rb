require 'sinatra'
require_relative '../scripts/qd.rb'

qd = QuickDev.new()

get '/' do
  @apps = QuickDev.get_apps()
  erb :index
end