#!/usr/bin/ruby
# encoding: utf-8
#
# author: Kyle Yetter
#

module Glance
class Report
module Configuration

  def self.included(target)
    target.extend(ClassMethods)
  end

  module ClassMethods
    def options
      @options ||=
        if superclass.respond_to?(:options)
          Hash.new do | h, k |
            if superclass.option?( k )
              k      = k.to_sym
              h[ k ] = superclass.options[ k ]
            end
          end.update( superclass.options )
        else
          {}
        end
    end

    def option( name )
      options[ name.to_sym ]
    end

    def option?( name )
      options.key?( name )
    end

    def option_shortcuts
      @option_shortcuts ||=
        if superclass.respond_to?(:option_shortcuts)
          Hash.new do | h, k |
            if superclass.option_shortcut?( k )
              k      = k.to_sym
              h[ k ] = superclass.option_shortcuts[ k ]
            end
          end.update( superclass.option_shortcuts )
        else
          {}
        end
    end

    def option_shortcut?( name )
      option_shortcuts.key?( name.to_sym )
    end

    def option_shortcut( name )
      option_shortcuts[ name.to_sym ]
    end

    def define_option( name, default_value = nil )
      name            = name.to_sym
      reader_name     = name
      if name.to_s =~ /^(.*)\?$/
        reader_name   = name
        name          = $1.to_sym
      end

      options[ name ] = default_value

      define_method( reader_name ) { configuration_value( name ) }
      define_method( :"#{ name }=" ) { | value | configuration[ name ] = value }

      self
    end

    def define_option_shortcut( name, value_set = {} )
      name                     = name.to_sym
      option_shortcuts[ name ] = Util.symbolize_keys value_set.clone
      self
    end
  end

  def configuration
    @configuration ||= self.class.options.clone
  end

  def configuration_value( key )
    key   = key.to_sym
    value = configuration[ key ]
    if value.respond_to?( :call )
      configuration[ key ] = value = value.call(self)
    end
    value
  end

  def configure( *options )
    [ options ].flatten.compact.each do | option |
      apply_option( option )
    end
    self
  end

  private

  def apply_option( option )
    if option.is_a?( ::Hash )
      configuration.update( Util.symbolize_keys( option ) )
    elsif self.class.option_shortcut?( option )
      configuration.update( self.class.option_shortcut( option ) )
    elsif self.class.option?( option )
      configuration[ option ] = true
    end
  end

end
end
end