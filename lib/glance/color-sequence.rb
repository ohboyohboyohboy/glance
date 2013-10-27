#!/usr/bin/ruby
# encoding: utf-8
#
# author: Kyle Yetter
#

module Glance
class ColorSequence
  include MonoclePrint::TerminalEscapes

  autoload :ANSI,    "glance/color-sequence/ansi"
  autoload :XTerm,   "glance/color-sequence/xterm"
  autoload :Konsole, "glance/color-sequence/konsole"

  def self.load( key, *args )
    klass = const_get( REGISTRY[ key.to_sym ] )
    klass.new( *args )
  end

  def self.registered_types
    REGISTRY.keys
  end

  def self.default_type
    :ANSI
  end

  REGISTRY =
    Hash.new( default_type ).
      update(
        xterm:   :XTerm,
        ansi:    :ANSI,
        konsole: :Konsole
      )

  def self.detect_type
    if ENV[ 'KONSOLE_DBUS_SESSION' ]
      :konsole
    elsif ENV[ 'TERM' ] =~ /xterm/i
      :xterm
    else
      default_type
    end
  end

  def self.detect_and_create( *args )
    load( detect_type, *args )
  end

  def self.code_sequence
    @code_sequence ||= []
  end

  def self.define_code_sequence( *codes )
    code_sequence.replace( [ codes ].flatten.compact )
    self
  end

  attr_accessor :position

  def initialize( start = rand( code_sequence.length ) )
    self.position = start
  end

  def next_code
    step
    code
  end

  def next_escape_string
    step
    escape_string
  end

  def step
    self.position = ( self.position + 1 ) % code_sequence.length rescue 0
  end

  def code( position = self.position )
    self.class.code_sequence[position]
  end

  def escape_string( position = self.position )
    make_escape( code( position ) )
  end

  private

  def make_escape( code )
    raise NotImplementedError
  end

  def code_sequence
    self.class.code_sequence
  end
end
end