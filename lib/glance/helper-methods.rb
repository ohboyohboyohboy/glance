#!/usr/bin/ruby
# encoding: utf-8
#
# author: Kyle Yetter
#

module Glance
module HelperMethods
  module_function

  def glance( object = self, *args, &block )
    Glance.at( object, *args, &block )
  end

  def g( object = self, *args, &block )
    output = MonoclePrint.stdout
    Glance.at( object, *args ) do | g |
      g.output = output
      yield( g ) if block_given?
      g.render( output )
    end
    nil
  end
end
end
