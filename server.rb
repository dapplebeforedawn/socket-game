#! /usr/bin/env ruby
#
# I realized after bumbling on to it being the right way than
# my idea of using to stacks of data, that either loop either
# reads from or writes to, but never both is basically the same
# as pipes (they also have a read and a write end).

#
# Ending the server:
#   You could do a signal, but then you can't pipeline.
#   You can kill the server by writing the the killpipe
#   ("kill_pipe" by default), E.g:
#     `echo "" > kill_pipe`
#
#   This lets you pipe the output (user scores!) into something
#   usefull like `column`.  E.g:
#     ````
#     ./server.rb | column -t  -s, | cat \
#       <(echo "Game Results:") \
#       <(echo "========================") -
#     ````
#

Thread.abort_on_exception = true

require 'socket'
require 'json'
require_relative File.join *%w( lib server client )
require_relative File.join *%W( lib server exit_by_pipe )

class GameSever

  SERVER_PORT     = 9000
  CYCLE_TIME      = 1

  @client_updates    = [{}]
  Thread.new do
    Socket.udp_server_loop(SERVER_PORT) do |msg, msg_src|
      remote  = msg_src.remote_address
      ip      = remote.ip_address
      data    = JSON.parse(msg)
      port    = data["port"]
      clients = @client_updates.last.clone
      client  = Client.new data["conf"], ip, port, ClientReq.new, data["win_width"], data["win_height"]
      key     = client.ident
      clients[key] ||= client
      clients[key].req.add_mvmts data["mvmt"]
      @client_updates << clients
    end
  end

  # Pull in the previous state and us it as a seed, 
  # applying changes from the @client_updates stack to work out
  # the new position and the new scores
  #
  # Lesson learned: Don't use the new state as the base, use the
  # old state as the base an FF changes on top of it  **mind blown**
  @game_states  = [{}]
  def self.calc_state
    clients = @client_updates.last.clone
    states  = @game_states.last.clone
    
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
    @game_states << scored_clients
    scored_clients
  end

  game_loop = Thread.new do
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
  end

  # Kill the program by writing to kill pipe
  ExitByPipe.join do
    @game_states.last.each do |k, v|
      puts [k, v.conf, v.score].join(',')
    end
  end

end
