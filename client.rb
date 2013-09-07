#! /usr/bin/env ruby

require 'socket'
require 'json'
CLIENT_PORT = ARGV[0] || 9001

server_ip   = '127.0.0.1'
server_port = 9000

# Send my movements to the server
sock = UDPSocket.new.tap{|s| s.connect(server_ip, server_port)}
msg  =  {conf: 'xefe', mvmt: 'j', port: CLIENT_PORT}.to_json
sock.send(msg, 0)

# Listen for server state updates
Thread.new do
  Socket.udp_server_loop(CLIENT_PORT) do |msg, msg_src|
    puts "got server respose!"
    puts msg
  end
end.join
