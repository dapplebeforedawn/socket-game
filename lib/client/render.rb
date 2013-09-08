require 'curses'
require_relative '../debug_log'
include Debug

Curses.init_screen
Curses.start_color
Curses.noecho
Curses.stdscr.keypad(true) # enable arrow keys
at_exit { Curses.close_screen }

class Render
  COLOR_OFF       = 0
  DAMAGE_COLOR    = 1
  SCORE_COLOR     = 2
  Curses.init_pair DAMAGE_COLOR, Curses::COLOR_WHITE, Curses::COLOR_RED
  Curses.init_pair SCORE_COLOR,  Curses::COLOR_WHITE, Curses::COLOR_BLUE

  def initialize(win, log, new_state, old_state, ident)
    @win        = win
    @log        = log
    @win_width  = win.maxx
    @win_height = win.maxy
    @new_state  = new_state
    @old_state  = old_state
    @ident      = ident
  end

  # Sweet use of a cloure bro
  def player_lambda client
    ->() do
      @win.setpos client.pos_y, client.pos_x
      @win.addch  client.conf.slice(0)
      @win.addch  client.conf.slice(1)

      @win.setpos client.pos_y+1, client.pos_x
      @win.addch  client.conf.slice(2)
      @win.addch  client.conf.slice(3)
    end
  end

  def draw
    @win.clear
    @win.box("|", "-")
    @new_state.clients.each do |client|
      player_lambda(client)[]
    end
    my_player = @new_state.clients.find {|c| isMe? c }
    colorize &player_lambda(my_player)
    @win.refresh
  end

  def update_score
    log "You Scored: #{me.score}"
  end

  def log(msg)
    @log.clear
    @log.setpos 0, 0
    @log.addstr msg
    @log.refresh
  end

  def me
    @new_state.clients.find { |state| state.ident == @ident }
  end
  private :me

  def isMe?(client)
    client.ident == @ident
  end
  private :isMe?

  def old_me
    return unless @old_state
    @old_state.clients.find { |state| state.ident == @ident }
  end
  private :old_me

  def scored?
    return false unless old_me
    old_me.score < me.score
  end
  private :scored?

  def damaged?
    return false unless old_me
    old_me.score > me.score
  end
  private :damaged?

  def colorize
    attrs = [Curses::A_BOLD]
    attrs << Curses::color_pair(DAMAGE_COLOR) if damaged?
    attrs << Curses::color_pair(SCORE_COLOR)  if scored?

    attrs.each { |attr| @win.attron(attr)  }
    yield
    attrs.each { |attr| @win.attroff(attr) }
  end
  private :colorize

end
