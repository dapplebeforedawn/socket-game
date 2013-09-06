#! /usr/bin/env ruby

require 'socket'
require 'json'
SERVER_PORT = 9000

clients    = {}
Socket.udp_server_loop(SERVER_PORT) do |msg, msg_src|
  remote   = msg_src.remote_address
  ip, port = remote.ip_address, remote.ip_port
  data     = JSON.parse(msg)
  clients[ip] ||= Client.new data["conf"], ip, port, ClientReq.new
  clients[ip].req.add_mvmts data["mvmt"]
end

def calc_state
  clients.map do |client|
    client.calc_position!

    colision_value = clients.inject(0) do |memo, other_client|
      memo +=1 if client.occludes_vowel(other_client)
      memo -=1 if other_client.occludes_vowel(client)
      memo
    end

    ClientRes.new client.pos_x, client.pos_y, colision_value
  end
end

class Client < Struct.new(:conf, :ip, :port, :req)
  attr_accessor :pos_x
  attr_accessor :pos_y

  def calc_position!
    req.mvmts.each do |mvmt|
      case mvmt
      when /h/i
        pos_x += -1
      when /j/i
        pos_y += -1
      when /k/i
        pos_y +=  1
      when /l/i
        pos_x +=  1
      end
    end
  end

  # We share a coord, and other is a vowell
  def occludes_vowel?(other)
    vowels       = /[aeiouy]/i
    pos_overlap? = ->(x_off, y_off){
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

class ClientRes < Struct.new(:pos_x, :pos_y, :colision_value)
end

class ClientReq
  MAX_MVMT = 3
  attr_reader :mvmts
  def add_mvmts mvmt
    @mvmts << mvmt
    @mvmts.shift if @mvmt.size > MAX_MVMT
    @mvmts
  end
end
