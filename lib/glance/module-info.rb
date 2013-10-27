#!/usr/bin/ruby
# encoding: utf-8
#
# author: Kyle Yetter
#

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
  def self.extract( mod, options = {} )
    sclass = Util.singleton_class( mod )
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
      imethds, cmeths = [], []
    end

    if options.fetch( :namespace, true )
      nested, constants =
        mod.constants.map do | c |
          auto  = mod.autoload?( c ) and next( ConstantInfo.new( c, auto ) )
          value = mod.const_get( c ) rescue next
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
      Util.singleton_class?(mod)
    )
  end

  def self.extract_ancestry( mod )
    ancestry   = [ mod ]
    inclusions = []
    mod.ancestors[1..-1].each do |a|
      if a.is_a?( Class )
        ancestry << a
      else
        inclusions << [ a, ancestry.last ]
      end
    end
    return [ ancestry, inclusions ]
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