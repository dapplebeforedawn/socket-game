#! /usr/bin/env ruby

require 'socket'
require 'json'
require 'curses'
require_relative './lib/client/render'
require_relative './lib/client/state'
require_relative './lib/debug_log'
include Debug

Thread.abort_on_exception = true

CLIENT_PORT     = ARGV[0] || 9001
SERVER_IP       = '127.0.0.1'
SERVER_PORT     = 9000
SOCK            = UDPSocket.new.tap{ |s| s.connect(SERVER_IP, SERVER_PORT) }
UPDATES         = []
SHIP            = ARGV[1]
GAME_WIN_HEIGHT = 10
GAME_WIN_WIDTH  = 60
LOG_WIN_HEIGHT  = 1

@win = Curses::Window.new( GAME_WIN_HEIGHT, GAME_WIN_WIDTH, 0              , 0 )
@log = Curses::Window.new( LOG_WIN_HEIGHT,  GAME_WIN_WIDTH, GAME_WIN_HEIGHT, 0 )

def notify_server(mvmt=' ')
  msg  = {}.update conf: SHIP, mvmt: mvmt, port: CLIENT_PORT, 
              win_width: GAME_WIN_WIDTH, win_height: GAME_WIN_HEIGHT 
  SOCK.send(msg.to_json, 0)
end

def ident
  "#{SOCK.addr.last}:#{CLIENT_PORT}"
end

def mvmt_valid?(mvmt)
  mvmt.match /[hjkl\s]/i
end
INVALID_MVMT = "How about h, j, k, l or <space> instead?"

# Send my initial movement to the server to connect
notify_server

# Listen for key presses and update the server
Thread.new do
  loop do
    mvmt = @win.getch
    next log(INVALID_MVMT) unless mvmt_valid?(mvmt)
    notify_server mvmt
  end
end

# Listen for server state updates
Thread.new do
  Socket.udp_server_loop(CLIENT_PORT) do |msg, msg_src|
    new_state = State.new(JSON.parse(msg))
    old_state = UPDATES.last
    UPDATES   << new_state
    render = Render.new(@win, @log, new_state, old_state, ident)
    render.draw
    render.update_score
  end
end.join
