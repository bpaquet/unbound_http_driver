require 'json'
require 'sinatra/reloader' if ENV['RACK_ENV'] == 'development'
require 'sinatra/base'
require 'yaml'

CONFIG_FILE = ENV['CONFIG_FILE'] || '/etc/unbound/unbound.conf'
LOCAL_DB = ENV['LOCAL_DB'] || 'unbound.yml'

def write_local config
  File.open(LOCAL_DB, 'w') {|io| io.write(YAML.dump(config))}
end

def read_local
  YAML.load(File.read(LOCAL_DB))
end

unless File.exist? LOCAL_DB
  config = YAML.load(File.read(CONFIG_FILE))
  config["server"].delete("local-zone")
  config["server"].delete("local-data")
  write_local({:server_config => config["server"], :zones => {}})
end

class UnboundHttpDriver < Sinatra::Base

  configure :development do
    register Sinatra::Reloader
  end

  get '/' do
    content_type :json
    JSON.dump(read_local)
  end

  get '/:zone' do
    content_type :json
    JSON.dump(read_local[:zones][params[:zone]])
  end

  put '/:zone/:name/:ip' do
    config = read_local
    unless config[:zones][params[:zone]]
      config[:zones][params[:zone]] = {}
    end
    return [409, 'Already exists'] if config[:zones][params[:zone]][params[:name]]
    config[:zones][params[:zone]][params[:name]] = params[:ip]
    write_local config
    'ok'
  end
  
  delete '/:zone/:name' do
    config = read_local
    unless config[:zones][params[:zone]] && config[:zones][params[:zone]][params[:name]]
      return [404, 'Not found']
    end
    config[:zones][params[:zone]].delete(params[:name])
    write_local config
    'ok'
  end

  post '/reload' do
    config = read_local
    c = "server:\n"
    config[:server_config].each do |k, v|
      c += "  #{k}: #{v}\n"
    end
    config[:zones].each do |k, v|
      c += "  local-zone: #{k} static\n"
      v.each do |name, ip|
        c += "  local-data: \"#{name}.#{k}. IN A #{ip}\"\n"
      end
    end
    File.open(CONFIG_FILE, 'w') {|io| io.write(c)}
    result = %x{/usr/sbin/unbound-control reload}
    puts "Reload output"
    puts result
    unless $?.exitstatus == 0
      
      return [500, 'unable to restart unbound'] 
    end
    result
  end

end
