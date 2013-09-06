#! /usr/bin/env ruby

require 'socket'
require 'json'
CLIENT_PORT = 9001

server_ip   = '127.0.0.1'
server_port = 9000


sock = UDPSocket.new.tap{|s| s.connect(server_ip, server_port)}
msg  =  {conf: 'xefe', mvmt: 'j', port: CLIENT_PORT}.to_json
sock.send(msg, 0)
