
# Becuase curses is going to be controlling the screen
# regular stdout logging isn't going to work. To see what's
# going on, start the client like: 
#   `./client.rb 2>log.txt` and `tail -f log.txt`

module Debug
  def p(msg)
    $stderr.puts msg.inspect
  end
end
