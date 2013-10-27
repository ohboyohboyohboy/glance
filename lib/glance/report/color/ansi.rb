#!/usr/bin/ruby
# encoding: utf-8

module IRB
module Help
class Colorizer
  @@colors = %w(
    31 32 33 34 35 36 37
    1;30 1;31 1;32 1;33 1;34 1;35
    1;36 1;37
  )
  
  def make_escape( color )
    "\e[#{ color }m"
  end
  
end
end
end