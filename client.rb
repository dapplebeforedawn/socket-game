#! /usr/bin/env ruby

require 'socket'
require 'json'
require 'curses'


class ClientState < Struct.new(:conf, :pos_x, :pos_y, :score, :ident)
end

class State
  attr_accessor :clients
  def initialize client_hashes
    @clients = client_hashes.map do |ch| 
      ClientState.new *ch.values
    end
  end
end

Thread.abort_on_exception = true

CLIENT_PORT     = ARGV[0] || 9001
SERVER_IP       = '127.0.0.1'
SERVER_PORT     = 9000
SOCK            = UDPSocket.new.tap{ |s| s.connect(SERVER_IP, SERVER_PORT) }
GAME_WIN_HEIGHT = 10
GAME_WIN_WIDTH  = 60
LOG_WIN_HEIGHT  = 1

SHIP            = ARGV[1]

Curses.init_screen
Curses.noecho
Curses.stdscr.keypad(true) # enable arrow keys
at_exit { Curses.close_screen }

@win = Curses::Window.new( GAME_WIN_HEIGHT, GAME_WIN_WIDTH, 0              , 0 )
@log = Curses::Window.new( LOG_WIN_HEIGHT,  GAME_WIN_WIDTH, GAME_WIN_HEIGHT, 0 )
@win.box("|", "-")

def draw(new_state)
  new_state.clients.each do |state|
    @win.setpos state.pos_y, state.pos_x
    @win.addch state.conf.slice(0)
    @win.addch state.conf.slice(1)

    @win.setpos state.pos_y+1, state.pos_x
    @win.addch state.conf.slice(2)
    @win.addch state.conf.slice(3)
  end
  @win.refresh
end

# Becuase curses is going to be controlling the scree
# regular stdout logging isn't going to work too see what's
# going on, start the client like: `./client.rb 2>log.txt` and `tail -f log.txt`
def debug_log(msg)
  $stderr.puts msg
end

def notify_server(mvmt=' ')
  msg  = {conf: SHIP, mvmt: mvmt, port: CLIENT_PORT, win_width: GAME_WIN_WIDTH, win_height: GAME_WIN_HEIGHT }.to_json
  SOCK.send(msg, 0)
end

def log(msg)
  @log.clear
  @log.setpos 0, 0
  @log.addstr msg
  @log.refresh
end

def ident
  "#{SOCK.addr.last}:#{CLIENT_PORT}"
end

def mvmt_valid?(mvmt)
  mvmt.match /[hjkl\s]/i
end
INVALID_MVMT = "How about h, j, k, l or <space> instead?"

def update_score(clients)
  me = clients.find { |state| state.ident == ident }
  log "You Scored: #{me.score}"
end

# Send my initial movement to the server to connect
notify_server
log "Use your VIM movement keys"

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
    debug_log msg
    new_state = State.new(JSON.parse(msg))
    draw         new_state
    update_score new_state.clients
  end
end.join
