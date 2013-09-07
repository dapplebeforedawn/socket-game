# All would-be mutating methods return a copy
# of the client.
class Client
  GAME_WIN_HEIGHT = 10
  GAME_WIN_WIDTH  = 60

  [ :pos_x, :pos_y, :score, :res,
    :conf,  :ip,    :port,  :req  ].each { |attr| attr_reader attr }

  def initialize conf, ip, port, req, pos_x=rand(GAME_WIN_WIDTH), pos_y=rand(GAME_WIN_HEIGHT)
    @conf  = conf
    @ip    = ip
    @port  = port
    @req   = req
    @pos_x = pos_x
    @pos_y = pos_y
    @score = 0
  end

  def ==(other)
    other.is_a? self.class &&
    ip   == other.ip       &&
    port == other.port
  end
  alias_method :eql?, :==

  def ident
    "#{ip}:#{port}"
  end

  def calc_response
    ClientRes.new(conf, pos_x, pos_y, score, ident)
  end

  def calc_colision(clients)
    client = clone
    clone.instance_eval do
      @score += clients.keys.inject(0) do |memo, other_client_ip|
        next memo if other_client_ip == ip
        memo +=1 if client.occludes_vowel?(clients[other_client_ip])
        memo -=1 if clients[other_client_ip].occludes_vowel?(client)
        memo
      end
    end
    client
  end

  def calc_position(prev_state)
    new_client = clone
    new_client.instance_eval do
      @pos_x = prev_state.pos_x
      @pos_y = prev_state.pos_y

      req.mvmts.each do |mvmt|
        case mvmt
        when /h/i
          @pos_x += -1
        when /j/i
          @pos_y +=  1
        when /k/i
          @pos_y += -1
        when /l/i
          @pos_x +=  1
        end
        keep_in_bounds
      end
    end
    new_client
  end

  def keep_in_bounds
     @pos_x = 0 if pos_x < 0
     @pos_y = 0 if pos_y < 0

     @pos_x = GAME_WIN_WIDTH  - 1 if pos_x >= GAME_WIN_WIDTH
     @pos_y = GAME_WIN_HEIGHT - 1 if pos_y >= GAME_WIN_HEIGHT
  end
  private :keep_in_bounds

  # We share a coord, and other is a vowell
  def occludes_vowel?(other)
    vowels       = /[aeiouy]/i
    pos_overlap = ->(x_off, y_off){
      other.pos_x+x_off == pos_x    &&
      other.pos_y+y_off == pos_y    ||
      other.pos_x+x_off == pos_x+1  &&
      other.pos_y+y_off == pos_y    ||
      other.pos_x+x_off == pos_x    &&
      other.pos_y+y_off == pos_y+1  ||
      other.pos_x+x_off == pos_x+1  &&
      other.pos_y+y_off == pos_y+1 
    }

      tl = other.conf.slice(0)
      tr = other.conf.slice(1)
      bl = other.conf.slice(2)
      br = other.conf.slice(3)

      tl.match(vowels) && pos_overlap[0,0] ||
      tr.match(vowels) && pos_overlap[1,0] ||
      bl.match(vowels) && pos_overlap[0,1] ||
      br.match(vowels) && pos_overlap[1,1]
  end
end

class ClientRes < Struct.new(:conf, :pos_x, :pos_y, :score, :ident)
end

class ClientReq
  MAX_MVMT = 3
  attr_reader :mvmts
  def initialize
    @mvmts = []
  end

  def add_mvmts mvmt
    @mvmts << mvmt
    @mvmts.shift if @mvmts.size > MAX_MVMT
    @mvmts
  end
end
