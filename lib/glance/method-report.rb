#!/usr/bin/ruby
# encoding: utf-8

module Glance
class MethodReport < Report
  def analyze( options = {} )
    extract_module( Util.singleton_class( object ), options )
  end

  def build_content( top )
    info    = analyze
    methods = info.instance_methods

    if methods.empty?
      top.line( "Methods:", "No methods found matching configuration" )
    else
      top.list( "Methods", format_method_list( methods ) )
    end

    top.leger
    if legend_modules = info.method_modules( :instance_methods ) and not legend_modules.empty?
      legend = legend_modules.map { |m| colorize( format_module(m), m ) }.join( " " )
      top.line( "Classes/Modules:", legend )
      top.line( "Visibility:     ", "public: __m__ / protected: [__m__] / private: (__m__)" )
    end
  end
end
end