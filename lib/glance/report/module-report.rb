#!/usr/bin/ruby
# encoding: utf-8

=begin      ::about::
author:     Kyle Yetter <kcy5b@yahoo.com>
created on: January 11, 2010
purpose:    library
summary:    introspection report construction and formatting for modules and classes
loads:      files required by this
autoloads:  autoload entries in this (e.g. YAML(yaml))
=end


module IRB
module Help
class ModuleReport
  Section = Struct.new( :title, :items ) do
    def initialize( title = nil, *items )
      super( title, items )
    end
    
    def empty?
      items.empty? or items.all? { | i | i.empty? }
    end
  end
  
  TitledList = Struct.new( :type, :title, :items ) do
    def empty?
      items.empty?
    end
  end
  
  
  include Monocle::Presentation
  
  @@default_options = {
    :public => true,
    :private => false,
    :protected => false,
    :singleton => true,
    :verbose => false
  }
  @@colors = Colorizer.new
  
  attr_accessor :color_map, :categories, :methods
  attr_reader   :module, :filters, :sclass
  
  def initialize( mod, *options )
    @module  = mod
    @sclass  = class << @module; self; end
    @filters = []
    @color_map = Hash.new do | h, k |
      h[ k ] = @@colors.next_escape
    end
    @configuration = @@default_options.clone
    configure( *options )
    initialize_view( @configuration )
  end
  
  def filter( positive = true, arg = nil, &block )
    if block_given?
      @filters.push( [ positive, block ] )
    else
      @filters.push( [ positive, arg ] )
    end
  end
  
  def configure( *options )
    for option in options
      case option
      when Hash
        @configuration.update( option )
      when :all!
        @filters.clear
        for setting in [ :verbose, :public, :protected, :private ]
          @configuration[ setting ] = true
        end
      when :all
        @filters.clear
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
        @filters << [ true, option ]
      when Regexp
        @filters << [ true, option ]
      end
    end
  end
  
  alias inspect to_s
  
private
  
  def render_content( out )
    @legend = []
    content = harvest_content
    
    title = underline( "#{ entity_type( @module ) } #{ @module.inspect }" )
    out.puts( "\e#3#{ title }" )
    out.puts
    out.indent( 2 ) do
      for section in content
        render_section( out, section )
      end
    end
    
    legend( out )
    
  end
  
  def render_section( out, section )
    section.empty? and return
    out.puts( "\e[1m#{ section.title }\e[0m" )
    out.indent( 2 ) do
      for list in section.items
        render_list( out, list )
      end
      out.puts
    end
  end
  
  def render_list( out, list )
    case list.type
    when :line
      out.puts( "#{ list.title }: #{ list.items }" )
    when :list
      out.puts( list.title )
      out.indent( 4 ) do
        out.list( list.items )
      end
    end
  end
  
  def harvest_content
    %w( Relationships Namespace Methods ).map! do | title |
      section = Section.new( title, [] )
      send( "harvest_#{ title.downcase }", section.items )
      section.items.delete_if { | list | list.empty? }
      section.empty? ? nil : section
    end.compact
  end
  
  
  def entity_type( entity )
    case entity
    when Class
      entity < Exception ? 'error' : 'class'
    when Module then 'module'
    else entity.class.to_s
    end
  end
  
  def harvest_methods( entities )
    imeths = filter_instance_methods( MethodInfo.extract_from( @module ) ).map! do | m |
      @legend << m.owner
      colorize( m.to_s, m.owner )
    end
    
    cmeths = filter_methods( MethodInfo.extract_from( @module, false ) ).map! do | m |
      @legend << m.owner
      colorize( m.to_s, m.owner )
    end
    entities << TitledList.new( :list, "#{ @module < Class ? "Class" : "Module" } Methods", cmeths )
    entities << TitledList.new( :list, "Instance Methods", imeths )
  end
  
  def harvest_namespace( entries )
    @module == ::Module and return
    nested = []
    constants = []
    space = false
    
    for c in @module.constants
      if @module.autoload?( c )
        nested << [ c, :auto, 'a' ]
        next
      end
      
      value = @module.const_get( c ) rescue next
      case value
      when Class
        type = value < Exception ? Exception : Class
        nested << [ c, value, type ]
      when Module
        nested << [ c, value, Module ]
      else
        constants << [ c, value.class ]
      end
    end
    
    nested.sort!.map! do | name, entity, type |
      signifier = type.to_s[ 0, 1 ]
      colorize( "[#{ signifier }] #{ name }", type )
    end
    
    entries << TitledList.new( :list, "Nested Entities", nested )
    
    constants.sort!.map! do | name, type |
      colorize( name, type )
    end
    
    entries << TitledList.new( :list, "Constants", constants )
  end
  
  def harvest_relationships( entries )
    inclusions = []
    ancestry = []
    extensions = @sclass.ancestors - Class.ancestors
    
    for a in @module.ancestors[ 1..-1 ]
      case a
      when Class then ancestry << a
      when Module then inclusions << [ a, ancestry.last ]
      end
    end
    
    inherit_chain = ancestry.map! { | cls | colorize( cls.inspect, cls ) }.join( ' < ' )
    entries << TitledList.new( :line, "Ancestry", inherit_chain )
    
    inclusions.map! do | imod, owner |
      name = colorize( imod.inspect, imod )
      owner and name << " (from #{ colorize( owner.inspect, owner ) })"
      name
    end
    entries << TitledList.new( :list, "Included Modules", inclusions )
    
    extensions.map! do | ext |
      colorize( ext.inspect, ext )
    end
    entries << TitledList.new( :list, "Extended Modules", extensions )
  end
  
  def colorize( str, key )
    esc = @color_map[ key ]
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
  
  def legend( out )
    @legend.uniq!
    members = sort_modules( @legend ).map do | m |
      colorize( format_module( m ), m )
    end
    
    unless @legend.empty?
      out.leger
      out.puts( "Legend: #{ members.join( ' ' ) }" )
    end
  end
  
  def filter_methods( method_list )
    verbose = @configuration[ :verbose ]
    
    visibilities =
      [ :public, :protected, :private ].select { |v| @configuration[ v ] }
    
    ignore = ignorable_modules
    unless verbose
      method_list = method_list.reject do | m |
        ignore.include?( m.owner ) && m.owner != @module or
          not visibilities.include?( m.visibility )
      end
    end
    
    for positive, test in @filters
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
    
    return method_list
  end
  
  def filter_instance_methods( method_list )
    verbose = @configuration[ :verbose ]
    
    #visibilities =
    #  [ :public, :protected, :private ]   # select { |v| @configuration[ v ] }
    #
    ignore = ignorable_modules
    unless verbose
      method_list = method_list.reject do | m |
        ignore.include?( m.owner ) && m.owner != @module # or
          # not visibilities.include?( m.visibility )
      end
    end
    
    for positive, test in @filters
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
    
    return method_list
  end
  
  def ignorable_modules
    Class.ancestors
  end
  
  def sort_modules( clodules )
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
  
  def underline( str )
    "\e[4m#{ str }"
  end
  
  def sort_modules!( mods )
    ancestors = mods.inject( {} ) { |h,m| h[ m ] = m.ancestors[ 1..-1 ]; h }
    mods.sort! do | m1, m2 |
      if ancestors[ m1 ].include?( m2 ) then -1
      elsif ancestors[ m2 ].include?( m1 ) then 1
      else 0
      end
    end
  end
end

end
end
