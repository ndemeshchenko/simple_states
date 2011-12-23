require 'bundler/setup'
require 'test/unit'
require 'test_declarative'
require 'ruby-debug'
require 'simple_states'

module ClassCreateHelper
  def create_class(&block)
    self.class.send(:remove_const, :Foo) if self.class.const_defined?(:Foo)
    self.class.const_set(:Foo, Class.new).tap do |klass|
      klass.class_eval do
        include SimpleStates
        instance_eval &block

        attr_accessor :state

        def initialize
          @state = :created
        end
      end
    end
  end
end