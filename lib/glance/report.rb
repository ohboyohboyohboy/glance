#!/usr/bin/ruby
# encoding: utf-8

require 'glance/report/configuration'
require 'glance/report/content-area'

module Glance
class Report
  include MonoclePrint::Presentation
  include TerminalFormatting
  include Configuration

  define_option :public?, true
  define_option :private?, false
  define_option :protected?, false
  define_option :ignorable_modules, proc { Class.ancestors }
  define_option :escape_style, proc { ColorSequence.detect_type }

  define_option_shortcut(
    :verbose,
    public:            true,
    protected:         true,
    private:           true,
    ignorable_modules: proc { [] }
  )

  define_option_shortcut(
    :all,
    public:      true,
    protected:   true,
    private:     true
  )

  attr_reader :object, :filters

  def initialize( object, *options )
    @object        = object
    @filters       = []
    options        = [ options ].flatten!
    configure( *options )
    initialize_view( configuration )
    yield( self ) if block_given?
  end

  def add_filter( arg = true, positive = true, &block )
    if block_given?
      positive = arg
      matcher  = block
    else
      matcher  = arg
    end

    filters.push( [ matcher, positive ] )
  end

  alias inspect to_s

  private

  def create_color_sequence
    ColorSequence.load( escape_style )
  end

  def render_content( output )
    content_list = ContentList.new
    build_content( content_list )
    content_list.render( output )
  end

  def build_content( content )
    fail NotImplementedError
  end

  def extract_methods( object, options = {} )
    MethodInfo.extract_from( object, extraction_options( options ) )
  end

  def extract_module( object, options = {} )
    ModuleInfo.extract( object, extraction_options( options ) )
  end

  def extraction_options( options = {} )
    {
      visibilities:        target_visibilities,
      instance:            true,
      filters:             filters,
      ignorable_modules:   ignorable_modules
    }.update( options )
  end

  def format_module( m )
    text = m.name || m.inspect
    text = "$#{ text }" if SafeExtract.singleton_class?( m )
    return text
  end

  def format_method_list( methods )
    colorize_list_by(methods, &:owner)
  end

  def format_constant_list( constants )
    colorize_list_by(constants) { |c| c.type || 'a' }
  end

  def format_file_list(files)
    files.map { |file| shorten_file_path(file) }
  end

  def colorize_list_by( list )
    list.map do |item|
      key = yield(item)
      colorize( item.to_s, key )
    end
  end

  def target_visibilities
    [:public, :protected, :private].select { |v| configuration_value(v) }
  end

  def apply_option( option )
    case option
    when Module
      add_filter { |m| m.owner <= option }
    when Regexp
      add_regexp_filter(option)
    when *ColorSequence.registered_types
      configuration[ :escape_style ] = option
    else
      super
    end
  end

  def add_regexp_filter(regexp)
    case regexp.to_s
    when %r<^(\(\?[-\w]+:)!(.*\))$>m
      pattern = Regexp.new("#{ $1 }#{ $2 }")
      add_filter { |m| m.name.to_s !~ pattern }
    else
      add_filter { |m| m.name.to_s =~ regexp }
    end
  end

  def entity_type( entity )
    case entity
    when Class
      entity < Exception ? 'error' : 'class'
    when Module then 'module'
    else entity.class.to_s
    end
  end

  def shorten_file_path(path)
    path =~ load_path_rx ? $'.to_s : path.to_s
  end

  def load_path_rx
    @load_path_rx ||= begin
      path_rx = Regexp.union($LOAD_PATH.map { |d| File.expand_path(d) })
      /^(#{ path_rx })\//
    end
  end
end
end
