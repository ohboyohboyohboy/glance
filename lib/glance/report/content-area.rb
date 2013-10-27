#!/usr/bin/ruby
# encoding: utf-8

require 'delegate'

module Glance
class Report
module BuilderMethods
  def section(title, *items, &block)
    add_content(Section.new(title, *items), &block)
  end

  def list(title, *items, &block)
    add_content(TitledList.new(title, *items), &block)
  end

  def line(text, *args, &block)
    item =
      if args.length >= 1
        TitledLineItem.new( text, args.shift )
      else
        LineItem.new( text )
      end

    add_content( item, &block )
  end

  def leger
    add_content(Leger.new)
  end

  def add_content(item)
    items.push(item)
    yield(item) if block_given?
    self
  end
end

module ContentArea
  include BuilderMethods
  include Enumerable
  include TerminalFormatting

  attr_accessor :title

  def initialize( title, *items )
    self.title = title.to_s
    self.items.concat( items )
  end

  def each
    return( enum_for( :each ) ) unless block_given?
    items.each { | item | yield( item ) }
  end

  def items
    @items ||= ContentList.new
  end

  def tidy
    items.tidy
    self
  end

  def empty?
    items.empty?
  end
end

class Section
  include ContentArea

  def render( output )
    unless empty?
      unless title.to_s.strip.empty?
        output.puts title
      end
      output.indent( 2 ) do
        items.render( output )
      end
    end
    output
  end
end

class LineItem
  include TerminalFormatting
  attr_accessor :text

  def initialize( text = '' )
    self.text = text.to_s
  end

  def empty?
    text.to_s.strip.empty?
  end

  def to_s
    text.to_s
  end

  def render( output )
    unless empty?
      output.puts( self.to_s )
    end
  end
end

class TitledLineItem < LineItem
  attr_accessor :title

  def initialize( title, text = '' )
    self.title = title
    super( text )
  end

  def to_s
    [ title, text ].reject { |s| s.to_s.empty? }.join( " " )
  end

  def render( output )
    unless empty?
      output.puts( self.to_s )
    end
  end
end

class Leger
  include TerminalFormatting
  def empty?
    false
  end

  def render( output )
    output.leger
  end
end

class TitledList
  include ContentArea

  def render(out)
    unless empty?
      out.puts( title )
      out.indent( 4 ) do
        out.list( items )
      end
    end
    out
  end
end

class ContentList < DelegateClass( Array )
  include BuilderMethods

  def initialize
    super([])
  end

  def items
    self
  end

  def empty?
    all?(&:empty?)
  end

  def tidy
    delete_if do |item|
      item.tidy if item.respond_to?(:tidy)
      item.empty?
    end
    self
  end

  def render(out)
    tidy
    unless empty?
      each do |item|
        item.respond_to?( :render ) ? item.render( out ) : out.puts( item )
      end
      out.puts
    end
    out
  end
end
end
end
