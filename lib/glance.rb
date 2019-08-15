#!/usr/bin/ruby
# encoding: utf-8
#
# author: Kyle Yetter
#

require 'monocle-print'
require 'set'

library_dir = File.expand_path( "..", __FILE__ )
$:.unshift( library_dir ) unless $:.include?( library_dir )

module Glance
  VERSION = "1.2.2"
  include MonoclePrint

  autoload :ColorSequence, "glance/color-sequence"
  autoload :ConstantInfo, "glance/constant-info"
  autoload :HelperMethods, "glance/helper-methods"
  autoload :ModuleInfo, "glance/module-info"
  autoload :ModuleReport, "glance/module-report"
  autoload :MethodInfo, "glance/method-info"
  autoload :MethodReport, "glance/method-report"
  autoload :Report, "glance/report"
  autoload :SafeExtract, "glance/safe-extract"
  autoload :TerminalFormatting, "glance/terminal-formatting"
  autoload :Util, "glance/util"

  def self.at( object, *args, &block )
    case object
    when ::Module
      ModuleReport.new( object, *args, &block )
    else
      MethodReport.new( object, *args, &block )
    end
  end

  def self.method_report( object, *args, &block )
    MethodReport.new( object, *args, &block )
  end

  def self.module_report( object, *args, &block )
    ModuleReport.new( object, *args, &block )
  end
end
