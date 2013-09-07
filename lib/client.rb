# All would-be mutating methods return a copy
# of the client.
class Client
  [ :pos_x, :pos_y, :score, :res,
    :conf,  :ip,    :port,  :req  ].each { |attr| attr_reader attr }

  def initialize conf, ip, port, req, win_width, win_height, pos_x=nil, pos_y=nil
    @conf       = conf
    @ip         = ip
    @port       = port
    @req        = req
    @win_width  = win_width
    @win_height = win_height
    @pos_x      = pos_x || rand(@win_width)
    @pos_y      = pos_y || rand(@win_height)
    @score      = 0
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
    client.instance_eval do
      state_score = clients[ident].score
      @score  = clients.keys.inject(state_score) do |memo, other_client_id|
        next memo if other_client_id == ident
        memo += 1 if occludes_vowel?(clients[other_client_id])
        memo -= 1 if clients[other_client_id].occludes_vowel?(self)
        memo
      end
    end
    client
  end

  def calc_position(next_state)
    new_client = clone
    new_client.instance_eval do

      next_state.req.mvmts.each do |mvmt|
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
     @pos_x = 1 if pos_x <= 1
     @pos_y = 1 if pos_y <= 1

     @pos_x = @win_width  - 3 if pos_x >= @win_width  - 3 
     @pos_y = @win_height - 3 if pos_y >= @win_height - 3
  end
  private :keep_in_bounds

  # We share a coord, and other is a vowell
  def occludes_vowel?(other)
    vowels      = /[aeiouy]/i
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

      !!(tl.match(vowels) && pos_overlap[0,0] ||
      tr.match(vowels) && pos_overlap[1,0] ||
      bl.match(vowels) && pos_overlap[0,1] ||
      br.match(vowels) && pos_overlap[1,1])
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
