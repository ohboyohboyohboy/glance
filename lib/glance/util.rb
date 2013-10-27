#!/usr/bin/ruby
# encoding: utf-8
#
# author: Kyle Yetter
#

module Glance
module Util
  TerminalEscapes = MonoclePrint::TerminalEscapes

  module_function

  def terminal_wrap( escape_name, string )
    "#{ TerminalEscapes.send( escape_name ) }#{ string }#{ TerminalEscapes.clear_attr }"
  end

  def singleton_class( object = self )
    object.singleton_class rescue object.class
  end

  def singleton_class?( klass )
    klass.ancestors.first != klass
  end

  def symbolize_keys( hash )
    symbolized = {}
    hash.each do | key, value |
      key = key.to_sym if key.respond_to?( :to_sym )
      symbolized[ key ] = value
    end
    symbolized
  end

  # Returns short abstract of long strings; not exceeding +range+
  # characters. If range is an integer then the minimum is 20%
  # of the maximum. The string is chopped at the nearest word
  # if possible, and appended by +ellipsis+, which defaults
  # to '...'.
  #
  #   CREDIT: George Moschovitis
  #   CREDIT: Trans
  def brief( string, range = 10, ellipsis = "..." )
    if Range === range
      min   = range.first
      max   = range.last
    else
      max   = range
      min   = max - (max/5).to_i
      range = min..max
    end

    if string.length > max
      cut_at  = string.rindex(/\b/, max) || max
      cut_at  = max if cut_at < min
      xstring = string.slice(0, cut_at)
      xstring.chomp(" ") + ellipsis
    else
      string
    end
  end

  def sort_class_hierarchy( hierarchy )
    hierarchy  = Array(hierarchy).flatten.grep(Module)
    klasses    = hierarchy.grep(Class).sort { |c1, c2| c1 <=> c2 || 0 }
    hierarchy -= klasses
    ordered    = []

    klasses.each_cons( 2 ) do |sub, sup|
      imods      = sort_module_list( ( sub.included_modules - sup.included_modules ) & hierarchy )
      hierarchy -= imods
      ordered.push( sub, *imods )
    end

    ordered.push( klasses.pop ) if klasses.last
    ordered.concat( sort_module_list( hierarchy ) )
    return ordered
  end

  def sort_module_list( mods )
    ancestors = {}
    mods.each { |m| ancestors[m] = m.ancestors[1..-1] }
    mods.sort do |m1, m2|
      if ancestors[m1].include?(m2) then -1
      elsif ancestors[m2].include?(m1) then 1
      else 0
      end
    end
  end

end
end
