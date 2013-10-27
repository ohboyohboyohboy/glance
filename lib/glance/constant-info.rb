#!/usr/bin/ruby
# encoding: utf-8
#
# author: Kyle Yetter
#

module Glance
ConstantInfo =
  Struct.new(
    :name,
    :autoload,
    :type
  )

class ConstantInfo
  def module?
    !autoload? and type <= Module
  end

  def class?
    !autoload? and type <= Class
  end

  def exception?
    !autoload? and type <= Exception
  end

  def autoload?
    !!autoload
  end


  def nested?
    autoload? or module?
  end

  def signifier
    if autoload?      then 'a'
    elsif exception?  then 'E'
    elsif class?      then 'C'
    elsif module?     then 'M'
    else                   nil
    end
  end

  def to_s
    if prefix = signifier
      "[#{ prefix }] #{ name }"
    else
      name
    end
  end
end
end
