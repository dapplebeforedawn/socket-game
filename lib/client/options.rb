require 'optparse'
module Options
  def self.parse!
    options = OpenStruct.new debug: false,       client_port: 9001,
                         server_ip: '127.0.0.1', server_port: 9000

    OptionParser.new do |opts|
      opts.on("-d", "--debug")                     { options.debug = true            }
      opts.on("-c", "--client_port=val", Integer)  { |arg| options.client_port = arg }
      opts.on("-h", "--server_ip=val",   String)   { |arg| options.server_ip   = arg }
      opts.on("-p", "--server_port=val", Integer)  { |arg| options.server_port = arg }

      opts.on_tail("-h", "--help")          { exec "grep ^#/<'#{__FILE__}'|cut -c4-" }
    end.parse!
    options
  end
end

