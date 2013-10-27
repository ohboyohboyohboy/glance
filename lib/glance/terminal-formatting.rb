#!/usr/bin/ruby
# encoding: utf-8
#
# author: Kyle Yetter
#

module Glance
module TerminalFormatting
  Escapes = MonoclePrint::TerminalEscapes

  private

  def color_map
    @color_map ||= Hash.new { |h,k| h[ k ] = next_color }
  end

  def color_sequence
    @color_sequence ||= create_color_sequence
  end

  def next_color
    color_sequence.next_escape_string
  end

  def colorize( string, key )
    escape = color_map[ key ]
    "#{ escape }#{ string }#{ Escapes.clear_attr }"
  end

  def terminal_wrap( format, string )
    "#{ Escapes.send(format) }#{ string }#{ Escapes.clear_attr }"
  end

  def underline( string )
    terminal_wrap( :underline, string )
  end

  def bold( string )
    terminal_wrap( :bold, string )
  end

  def create_color_sequence
    ColorSequence.detect_and_create
  end
end
end