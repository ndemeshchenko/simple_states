require 'active_support/core_ext/module/delegation'
require 'hashr'

module SimpleStates
  class Event
    attr_accessor :name, :options

    def initialize(name, options = {})
      @name = name
      @options = Hashr.new(options) do
        def except
          self[:except]
        end
      end
    end

    def saving
      @saving = true
      yield.tap { @saving = false }
    end

    def call(object, *args)
      return if skip?(object, args)

      raise_invalid_transition(object) unless can_transition?(object)
      run_callbacks(object, :before, args)

      yield.tap do
        set_state(object)
        run_callbacks(object, :after, args)
        object.save! if @saving
      end
    end

    def merge(other)
      other.options.each do |key, value|
        options[key] = [options[key], value].compact unless key == :to
      end
    end

    protected

    def skip?(object, args)
      result = false
      result ||= !send_methods(object, options.if, args) if options.if?
      result ||= send_methods(object, options.unless, args) if options.unless?
      result
    end

    def can_transition?(object)
      !options.from || object.state && Array(options.from).include?(object.state)
    end

    def run_callbacks(object, type, args)
      send_methods(object, options.send(type), args)
    end

    def set_state(object)
      if state = target_state(object)
        object.past_states << object.state if object.state
        object.state = state.to_sym
        object.send(:"#{state}_at=", Time.now) if object.respond_to?(:"#{state}_at=")
        object.save! if @saving
      end
    end

    def target_state(object)
      options.to || :"#{name}ed".tap do |state|
        raise_unknown_target_state(object) unless object.class.states.include?(state)
      end
    end

    def send_methods(object, methods, args)
      Array(methods).inject(false) { |result, method| result | send_method(object, method, args) } if methods
    end

    def send_method(object, method, args)
      object.send method, *case arity = self.arity(object, method)
                             when 0;
                               []
                             when -1;
                               [name].concat(args)
                             else
                               ; [name].concat(args).slice(0..arity - 1)
                           end
    end

    def arity(object, method)
      object.class.instance_method(method).arity rescue 0
    end

    def raise_invalid_transition(object)
      raise TransitionException, "#{object.inspect} can not receive event #{name.inspect} while in state #{object.state.inspect}."
    end

    def raise_unknown_target_state(object)
      raise TransitionException, "can not find target state for #{object.inspect} for event #{name.inspect}."
    end
  end
end