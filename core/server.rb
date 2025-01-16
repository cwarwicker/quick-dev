require 'sinatra'
require_relative '../scripts/qd.rb'

qd = QuickDev.new()

get '/' do
  @services = qd.get_service_info('project') + qd.get_service_info('core')
  erb :index
end