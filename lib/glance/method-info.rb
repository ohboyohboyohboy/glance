#!/usr/bin/ruby
# encoding: utf-8

module Glance
MethodInfo =
  Struct.new(
    :name,
    :singleton,
    :visibility,
    :owner
  )

class MethodInfo
  extend SafeExtract

  def self.extract_from( clodule, options = {} )
    instance     = options.fetch( :instance, ::Module === clodule )
    visibilities = options.fetch( :visibilities ) { [:public, :protected, :private] }
    filters      = options.fetch( :filters ) { [] }
    ignorable    = options.fetch( :ignorable_modules ) { [] }
    target       = instance ? clodule : singleton_class_of( clodule )
    methods      = []

    visibilities.each do |visibility|
      SafeExtract.send( :"safe_#{ visibility }_instance_methods", target ).each do | name |
        im = safe_instance_method( target, name ) rescue next
            #begin
            #  warn("skipping method info extraction for `%s::%s' due to error:" % [clodule, name])
            #  warn("  %s: %s" % [$!.class, $!.message])
            #  next
            #end

        unless ignorable.include?( im.owner ) and target != im.owner
          methods << new(name, !instance, visibility, im.owner)
        end
      end
    end

    filters.inject( methods ) do | list, filter |
      matcher, positive = filter
      positive ? list.select(&matcher) : list.reject(&matcher)
    end.sort_by { |m| m.name }
  end

  def private?
    visibility == :private
  end

  def protected?
    visibility == :protected
  end

  def public?
    visibility == :public
  end

  def singleton?
    !!singleton
  end

  def to_s
    string = name.to_s
    protected? and string = '[' << string << ']'
    private? and string = '(' << string << ')'
    return string
  end

  def destructive?
    name =~ /!$/
  end

  alias bang? destructive?

  def predicate?
    name =~ /\?$/
  end

  def to_unbound_method
    SafeExtract.safe_instance_method( owner, name )
  end

  def inspect
    owner.name << (singleton ? '.' : '#') << name.to_s
  end
end  # MethodInfo
end