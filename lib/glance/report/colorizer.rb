#!/usr/bin/ruby
# encoding: utf-8

module IRB
module Help
class Colorizer
  def initialize( start = -1 )
    @position = start
  end
  
  def reset
    @position = -1
  end
  
  def next_escape
    @position += 1
    @position %= @@colors.length
    color = @@colors[ @position ]
    make_escape( color )
  end
  
end

if ENV[ 'KONSOLE_DBUS_SESSION' ]
  require 'irb-ext/report/color/konsole'
elsif ENV[ 'TERM' ] =~ /xterm/i
  require 'irb-ext/report/color/xterm'
else
  require 'irb-ext/report/color/ansi'
end
end
end