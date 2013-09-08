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

