local_dir = File.dirname(__FILE__)
$LOAD_PATH << local_dir

require 'unbound_http_driver'

run UnboundHttpDriver.new

