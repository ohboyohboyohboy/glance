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
    puts Glance.at( object, *args, &block )
    object
  end
end
end
