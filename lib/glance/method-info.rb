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
  def self.extract_from( clodule, options = {} )
    instance     = options.fetch( :instance, clodule.is_a?( ::Module ) )
    visibilities = options.fetch( :visibilities ) { [:public, :protected, :private] }
    filters      = options.fetch( :filters ) { [] }
    ignorable    = options.fetch( :ignorable_modules ) { [] }
    target       = instance ? clodule : Util.singleton_class( clodule )
    methods      = []

    visibilities.each do |visibility|
      Array(target.send(:"#{visibility}_instance_methods")).each do |name|
        im =
          target.instance_method(name) rescue
            begin
              warn("skipping method info extraction for `%s::%s' due to error:" % [clodule, name])
              warn("  %s: %s" % [$!.class, $!.message])
              next
            end

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
    owner.instance_method(name)
  end

  def inspect
    owner.name << (singleton ? '.' : '#') << name.to_s
  end
end  # MethodInfo
end