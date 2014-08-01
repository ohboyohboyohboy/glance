#!/usr/bin/ruby
# encoding: utf-8
#
# author: Kyle Yetter
#

require 'set'

module Glance
ModuleInfo =
  Struct.new(
    :name,
    :ancestry,
    :inclusions,
    :extensions,
    :nested,
    :constants,
    :class_methods,
    :instance_methods,
    :singleton
  )

class ModuleInfo
  extend SafeExtract

  def self.extract( mod, options = {} )
    sclass = singleton_class_of( mod )
    name   = mod.name || mod.inspect

    if options.fetch( :relationships, true )
      ancestry, inclusions  = extract_ancestry( mod )
      sancestry, extensions = extract_ancestry( sclass )
    else
      ancestry, inclusions, extensions = [], [], []
    end

    if options.fetch( :methods, true )
      imeths   = MethodInfo.extract_from( mod, options.merge( instance: true ) )
      cmeths   = MethodInfo.extract_from( mod, options.merge( instance: false ) )
    else
      imeths, cmeths = [], []
    end

    if options.fetch( :namespace, true )
      nested, constants =
        safe_constants( mod ).map do | c |
          auto  = safe_autoload?( mod, c ) and next( ConstantInfo.new( c, auto ) )
          value = safe_const_get( mod, c ) rescue next
          ConstantInfo.new( c, false, value.class )
        end.
        compact.
        partition { |c| c.nested? }.
        map { |list| list.sort_by( &:name ) }
    else
      nested, constants = [], []
    end

    new(
      name,
      ancestry,
      inclusions,
      extensions,
      nested,
      constants,
      cmeths,
      imeths,
      singleton_class?(mod)
    )
  end

  def self.extract_ancestry( mod )
    ancestry   = [ mod ]
    inclusions = []
    safe_ancestors( mod )[ 1..-1 ].each do | a |
      if a.is_a?( Class )
        ancestry << a
      else
        inclusions << [ a, ancestry.last ]
      end
    end
    return [ ancestry, inclusions ]
  end


  def files
    counts =
      all_methods.each_with_object(Hash.new(0)) do |m, c|
        file = m.file and c[file] += 1
      end
    counts.keys.sort_by { |file| -counts[file] }
  end

  def all_methods
    class_methods + instance_methods
  end

  def method_modules( from = :all_methods )
    Util.sort_class_hierarchy( send( from ).map { |m| m.owner }.compact.uniq )
  end

  def singleton?
    !!singleton
  end
end
end
