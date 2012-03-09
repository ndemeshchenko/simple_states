A slim statemachine-like support LIB focussed on the use in Travis CI.

## Usage

Define states and events like this:

    class Foo
      include SimpleStates

      states :created, :started, :finished

      event :start,  :from => :created, :to => :started,  :if => :startable?
      event :finish, :to => :finished, :after => :cleanup

      attr_accessor :state

      def start
        # start foo
      end
    end

Including the SimpleStates module to your class is currently required. We'll add
hooks for ActiveRecord etc later.

SimpleStates expects your model to support attribute accessors for `:state`.

Event options have the following well-known meanings:

    :from   # valid states to transition from
    :to     # target state to transition to
    :if     # only proceed if the given method returns true
    :unless # only proceed if the given method returns false
    :before # run the given method before running `super` and setting the new state
    :after  # run the given method at the very end

All of these options except for `:to` can be given as a single symbol or string or
as an Array of symbols or strings.

Calling `event` will effectively add methods to a proxy module which is
included to the singleton class of your class' instances. E.g. declaring `event
:start` in the example above will add a method `start` to a module included to
the singleton class of instances of `Foo`.

This method will

1. check if `:if`/`:except` conditions apply (if given) and just return from the method otherwise
2. check if the object currently is in a valid `:from` state (if given) and raise an exception otherwise
3. run `:before` callbacks (if given)
4. call `super` if Foo defines the current method (i.e. call `start` but not `finish` in the example above)
5. add the object's current state to its `past_states` history
6. set the object's `state` to the target state given as `:to`
7. set the object's `[state]_at` attribute to `Time.now` if the object defines a writer for it
8. run `:after` callbacks (if given)

You can define options for all events like so:

    event :finish, :to => :finished, :after => :cleanup
    event :all, :after => :notify

This will call :cleanup first and then :notify on :finish.
