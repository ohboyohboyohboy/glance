#!/usr/bin/ruby
# encoding: utf-8

module Glance
class ModuleReport < Report

  define_option :relationships?, true
  define_option :namespace?, proc { |report| report.target_module != ::Module }
  define_option :methods?, true

  alias_method :target_module, :object

  def title
    "#{ entity_type( target_module ) } #{ format_module( target_module ) }"
  end

  def analyze( options = {} )
    ModuleInfo.extract( object, extraction_options( options ) )
  end

  def extraction_options( options = {} )
    super(
      {
        relationships:   relationships?,
        namespace:       namespace?,
        methods:         methods?
      }.update( options )
    )
  end

  def build_content( top )
    info = analyze

    top.leger
    top.line( title )
    top.leger

    top.section( "" ) do | content |
      if relationships?
        inherit_chain = info.ancestry.map { | c | colorize(format_module(c), c) }.join(' < ')

        content.section( "Relationships" ) do |section|
          section.line( "Ancestry:", inherit_chain )
          section.list( "Included Modules", format_module_list(info.inclusions) )
          section.list( "Extended Modules", format_module_list(info.extensions) )
        end
      end

      if namespace?
        content.section( "Namespace" ) do |section|
          section.list( "Nested Entities", format_constant_list( info.nested ) )
          section.list( "Constants", format_constant_list( info.constants ) )
        end
      end

      if methods?
        content.section( "Methods" ) do |section|
          class_label = "#{ target_module.is_a?( Class ) ? 'Class' : 'Module' } Methods"
          section.list( class_label, format_method_list( info.class_methods ) )
          section.list( "Instance Methods", format_method_list( info.instance_methods ) )
        end
      end
    end

    top.leger
    if legend_modules = info.method_modules and not legend_modules.empty?
      legend = legend_modules.map { |m| colorize( format_module(m), m ) }.join( " " )
      top.line( "Legend:", legend )
    end
  end

  def format_module_list(modules)
    modules.map do | mod, owner |
      name = colorize(format_module(mod), mod)
      name << " (from #{ colorize( owner.inspect, owner ) })" if owner
      name
    end
  end
end
end