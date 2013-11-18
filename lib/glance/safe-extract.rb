#!/usr/bin/ruby
# encoding: utf-8
#
# author: Kyle Yetter
#

module Glance
module SafeExtract
  [
    [
      Module,
      %w(
        ancestors
        constants
        autoload?
        const_get
        instance_method
        public_instance_methods
        protected_instance_methods
        private_instance_methods
      )
    ],
    [
      Object,
      %w(
        class
        singleton_class
      )
    ]
  ].each do | source_module, method_list |
    method_list.each do | method |
      method  = method.to_sym
      unbound = source_module.instance_method( method )
      define_method( :"safe_#{ method }" ) do |object, *args|
        begin
          unbound.bind( object ).call( *args )
        rescue TypeError
          object.respond_to?( method ) ? object.send( method, *args ) : raise
        end
      end
      module_function :"safe_#{ method }"
    end
  end

  def singleton_class_of( object )
    safe_singleton_class( object ) rescue safe_class( object )
  end

  def singleton_class?( klass )
    safe_ancestors( klass ).first != klass
  end

  module_function :singleton_class_of, :singleton_class?

end
end