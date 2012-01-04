module SimpleStates
  class States < Module
    class << self
      def init(object)
        object.singleton_class.send(:include, proxy_for(object.class))
        object.state = object.class.initial_state
      end

      def proxy_for(klass)
        klass.const_defined?(:States, false) ? klass::States : klass.const_set(:States, new(klass.events))
      end
    end

    def initialize(events)
      events.each { |event| define_event(event) }
    end

    def define_event(event)
      define_method(event.name) do |*args|
        event.call(self, *args) do
          super(*args) if self.class.method_defined?(event.name)
        end
      end

      define_method(:"#{event.name}!") do |*args|
        send(event.name, *args)
        save!
      end
    end
  end
end