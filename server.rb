#! /usr/bin/env ruby

require 'socket'
require 'json'
require_relative './lib/client'

class GameSever
  Thread.abort_on_exception = true
  SERVER_PORT     = 9000
  CYCLE_TIME      = 1

  CLIENTS    = [{}]
  Thread.new do
    Socket.udp_server_loop(SERVER_PORT) do |msg, msg_src|
      remote  = msg_src.remote_address
      ip      = remote.ip_address
      data    = JSON.parse(msg)
      port    = data["port"]
      clients = CLIENTS.last.clone
      client  = Client.new data["conf"], ip, port, ClientReq.new, data["win_width"], data["win_height"]
      key     = client.ident
      clients[key] ||= client
      clients[key].req.add_mvmts data["mvmt"]
      CLIENTS << clients
    end
  end

  STATES  = [{}]
  def self.calc_state
    clients = CLIENTS.last.clone
    states  = STATES.last.clone
    
    # Every client not in state gets added
    states_inited = clients.keys.inject(states) do |memo, client_ip|
      next memo if memo[client_ip]
      initial = clients[client_ip].clone
      memo.update({client_ip => initial})
    end
    moved_clients  = states_inited.merge(states_inited) do |key, ov|
      ov.calc_position(clients[key])
    end
    scored_clients = moved_clients.merge(moved_clients) do |key, ov|
      ov.calc_colision(moved_clients)
    end
    STATES << scored_clients
    #p scored_clients.values.map &:score
    scored_clients
  end

  Thread.new do
    loop do
      clients = calc_state
      response = clients.map do |client_ip, client|
        client.calc_response.to_h
      end
      clients.each do |ip, client|
        sock = UDPSocket.new.tap{|s| s.connect(client.ip, client.port)}
        msg  = response.to_json
        sock.send(msg, 0)
      end
      sleep CYCLE_TIME
    end
  end.join

end
