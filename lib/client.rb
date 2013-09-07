class Client
  [ :pos_x, :pos_y, :score, :res,
    :conf,  :ip,    :port,  :req  ].each { |attr| attr_accessor attr }

  def initialize conf, ip, port, req
    @conf  = conf
    @ip    = ip
    @port  = port
    @req   = req
    @pos_x = 0
    @pos_y = 0
    @score = 0
  end

  def ==(other)
    other.is_a? self.class &&
    ip   == other.ip       &&
    port == other.port
  end
  alias_method :eql?, :==

  def calc_response
    ClientRes.new(conf, pos_x, pos_y, score)
  end

  def calc_colision(clients)
    clone.tap do |client|
      client.score += clients.keys.inject(0) do |memo, other_client_ip|
        next memo if other_client_ip == ip
        memo +=1 if client.occludes_vowel?(clients[other_client_ip])
        memo -=1 if clients[other_client_ip].occludes_vowel?(client)
        memo
      end
    end
  end

  def calc_position(prev_state)
    clone.tap do |new_client| 
      new_client.pos_x = prev_state.pos_x
      new_client.pos_y = prev_state.pos_y

      new_client.req.mvmts.each do |mvmt|
        case mvmt
        when /h/i
          new_client.pos_x += -1
        when /j/i
          new_client.pos_y += -1
        when /k/i
          new_client.pos_y +=  1
        when /l/i
          new_client.pos_x +=  1
        end
      end
    end
  end

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

class ClientRes < Struct.new(:conf, :pos_x, :pos_y, :score)
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
