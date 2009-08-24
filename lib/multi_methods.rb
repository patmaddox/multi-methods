module MultiMethods
  def self.included(base)
    base.extend ClassMethods
  end
  module ClassMethods
    def multi_method name, &block
      dispatcher = dispatcher_for name, &block
      define_multi_method_using_dispatcher name, dispatcher
    end

    def dispatchers
      @dispatchers ||= {}
    end

    def dispatcher_for name, &block
      unless dispatchers[name]
        dispatchers[name] = MultiMethod::Dispatcher.new
      end
      dispatchers[name].instance_eval &block
      dispatchers[name]
    end

    private
    def define_multi_method_using_dispatcher(name, dispatcher)
      define_method name do |*args|
        dispatcher.call(*args)
      end
    end
  end


  class MultiMethod
    class Dispatcher
      def initialize
        @implementations = Hash.new(Proc.new {})
      end

      module DSL
        def router &block
          @dispatching_method = block
        end

        def implementation_for symbol, &block
          @implementations[symbol] = block
        end
      end
      include DSL

      def call(*args)
        dispatching_value = @dispatching_method.call(*args)
        proc = code_for dispatching_value
        proc.call(*args)
      end

private
      def code_for dispatching_value
        @implementations[dispatching_value]
      end
    end
  end
end
