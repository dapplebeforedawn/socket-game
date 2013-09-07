#! /usr/bin/env ruby

require 'socket'
require 'json'
require 'curses'

class ClientState < Struct.new(:conf, :pos_x, :pos_y, :score)
end

class State
  attr_accessor :clients
  def initialize client_hashes
    @clients = client_hashes.map do |ch| 
      ClientState.new ch["conf"], ch["pos_x"], ch["pos_y"], ch["score"]
    end
  end
end

CLIENT_PORT     = ARGV[0] || 9001
SERVER_IP       = '127.0.0.1'
SERVER_PORT     = 9000
GAME_WIN_HEIGHT = 10
GAME_WIN_WIDTH  = 60
LOG_WIN_HEIGHT  = 1

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
  sock = UDPSocket.new.tap{|s| s.connect(SERVER_IP, SERVER_PORT)}
  msg  =  {conf: 'xefe', mvmt: mvmt, port: CLIENT_PORT}.to_json
  sock.send(msg, 0)
end

def log(msg)
  @log.addstr msg
  @log.refresh
  @log.setpos 0, 0
end

def mvmt_valid?(mvmt)
  mvmt.match /[hjkl\s]/i
end
INVALID_MVMT = "How about h, j, k, l or <space> instead?"

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
    draw new_state
  end
end.join
