#!/usr/bin/ruby
# encoding: utf-8


if defined?( MethodsOnDemand )

  class Class
    on_demand  :singleton?, :metaclass?, :target_class, :target_object, 'core/class/metaclass'
  end

  module Kernel
    on_demand :singleton_class, 'core/kernel/singleton_class'
  end

else
  require 'core/kernel/singleton_class'
  require 'core/class/metaclass'
end

module Glance
class MethodReport
  defined?( MethodInfoCache ) and @@cache = MethodInfoCache.new

  @@default_options = {
    :public    => true,
    :private   => false,
    :protected => false,
    :singleton => true,
    :verbose   => false
  }
  @@colors = Colorizer.new

  attr_accessor :color_map, :categories, :methods
  attr_reader   :object, :filters

  def initialize( object, *options )
    @object  = object
    @filters = []
    configure( *options )
  end

  def color_map
    @color_map ||=
      categories.inject( {} ) do | map, category |
        map[ category ] = @@colors.next_escape
        map
      end
  end

  def categories
    @categories ||= method_list.group_by { |m| m.owner }.keys
  end

  if defined?( @@cache )
    def method_list
      @method_list ||=
        @object.singleton_methods.empty? ? @@cache[ @object.class ].clone :
        MethodInfo.extract_from( @object.singleton_class )
    end
  else
    def method_list
      @method_list ||=
        @object.singleton_methods.empty? ? MethodInfo.extract_from( @object.class ) :
          MethodInfo.extract_from( @object.singleton_class )
    end
  end

  def filter( positive = true, arg = nil, &block )
    if block_given?
      @filters.push( [ positive, block ] )
    else
      @filters.push( [ positive, arg ] )
    end
  end

  def configure( *options )
    @configuration = @@default_options.clone

    for option in options
      case option
      when Hash
        @configuration.update( option )
      when :all!
        filters.clear
        for setting in [ :verbose, :public, :protected, :private ]
          @configuration[ setting ] = true
        end
      when :all
        filters.clear
        for setting in [ :public, :protected, :private ]
          @configuration[ setting ] = true
        end
      when :protected
        @configuration[ :protected ] = true
      when :private
        @configuration[ :private ] = true
      when :public
        @configuration[ :public ] = true
      when :verbose
        @configuration[ :verbose ] = true
      when Module
        filters.push( [ true, option ] )
      when Regexp
        filters.push( [ true, option ] )
      end
    end
  end

  def render
    Monocle::OutputDevice.buffer do | out |
      build_method_chart( out )
      out.leger
      build_legend( out )
    end
  end

  alias inspect render
  alias to_s render

private

  def colorize( str, esc )
    "#{ esc }#{ str }\e[0m"
  end

  def format_module( m )
    case m
    when Class
      if m.anonymous?
        if m.metaclass? then ( '$' << m.target_class.name )
        elsif m.singleton?
          singleton_object = m.target_object
          if singleton_object.equal?( @object ) then '$self'
          else
            '$(' << singleton_object.to_s.brief( 10 ) << ')'
          end
        else
          m.inspect
        end
      else
        m.name
      end
    when Module then m.inspect
    end
  end

  def build_legend( out )
    clodules = ordered_module_list
    legend_content =
      clodules.map do | m |
        colorize( format_module( m ), color_map[ m ] )
      end
    out.puts( "Classes/Modules: " << legend_content.join( ' ' ) )
    out.puts(
      'Visibility: public: _meth_ / protected: [_meth_] / private: (_meth_)'
    )
  end

  def build_method_chart( out )
    method_list = filtered_methods.map do | m |
      ( owner = m.owner ) ? colorize( m.to_s, color_map[ owner ] ) : m.to_s
    end
    out.list( method_list )
  end

  def filtered_methods
    method_list = initial_method_list
    for positive, test in filters
      enum = positive ? method_list.select : method_list.reject
      method_list =
        case test
        when Regexp
          enum.each { |m| m.name =~ test }
        when Module
          enum.each { |m| m.owner <= test }
        when Proc
          enum.each( &test )
        end
    end
    @categories = method_list.map { |m| m.owner }.uniq
    return method_list
  end

  def initial_method_list
    method_list = self.method_list
    verbose = @configuration[ :verbose ]

    visibilities =
      [ :public, :protected, :private ].select { |v| @configuration[ v ] }

    method_list.select do |m|
      verbose || !ignorable_modules.include?( m.owner ) and
      visibilities.include?( m.visibility )
    end
  end

  def ignorable_modules
    Object.ancestors
  end

  def ordered_module_list
    clodules = self.categories
    klasses = clodules.grep( Class ).sort { |c1, c2| c1 <=> c2 || 0 }

    clodules -= klasses
    ordered = []

    klasses.each_cons( 2 ) do |sub, sup|
      imods = ( sub.included_modules - sup.included_modules ) & clodules
      clodules -= imods
      sort_modules!( imods )
      ordered.push( sub )
      ordered.concat( imods )
    end

    sort_modules!( clodules )
    ordered.push( klasses.last ) if klasses.last
    ordered.concat( clodules )
    return ordered
  end

  def sort_modules!( mods )
    ancestors = mods.inject( {} ) { |h,m| h[ m ] = m.ancestors[ 1..-1 ]; h }
    mods.sort! do |m1,m2|
      if ancestors[ m1 ].include?( m2 ) then -1
      elsif ancestors[ m2 ].include?( m1 ) then 1
      else 0
      end
    end
  end
end
end
end
