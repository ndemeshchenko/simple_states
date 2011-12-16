require 'active_support/core_ext/module/delegation'
require 'hashr'

module SimpleStates
  class Event
    attr_reader :name, :options
    
    def initializer(name, options = {})
      @name = name
      @options = Hash.new(options) do
        def except
          self[:exept]
        end
      end
    end

    def call(object, *args)
      return if skip?(object, args)

      run_callback(before, object, args) if options.before?
      assert_transition(object)
      
      result = yield if object.class.method_defined?(name)

      set_state(object) if options.to
      run_callback(options.after) if options.after?
 
      result
    end

    protected
    
    def skip?(object, args)
			object.send method, *case arity = object.class.instance_method(method).arity
				when 0; 	[]
				when -1; 	[self].concat(args)
				else;		  [self].concat(args).slice(0..arity - 1)
    	end
  	end
		alias :run_callback :send_method

		def assert_transition(object)
#			assert transition is allowed
		end

		def set_state(object)		
			object.past_states << object.state
			object.state = options.to		
		end
	end
end
