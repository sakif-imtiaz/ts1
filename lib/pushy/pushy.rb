module Pushy
  class Result
    attr_reader :skipt, :value
    def initialize(value: nil, skipt: false)
      @skipt, @value = skipt, value
    end
  end

  module Helpers
    def skipt
      Result.new(skipt: true)
    end
    module_function :skipt

    def result(value)
      Result.new(value: value)
    end
    module_function :result
  end

  class Subscription
    attr_reader :block, :observable
    attr_accessor :description

    def initialize(observable, &blk)
      @observable = observable
      @description = false
      @block = blk
    end

    def next(next_value)
      @block.call(next_value)
    end

    def print_description(indent = 0)
      puts " "*indent + " " + description
    end

    def description
      @description || self.class.name
    end
  end

  class Observable
    include Helpers
    attr_reader :listeners, :transformers
    attr_accessor :description, :current_value

    def print_description(indent = 0)
      puts " "*indent + " " + description + " -- " + transformers.map { |t| t.class.name }.join(", ")
      @listeners.each { |listener| listener.print_description(indent + 1) }
    end

    def description
      @description || self.class.name
    end

    def initialize(*param_transformers)
      trs = param_transformers.empty? ? [idempotent] : param_transformers
      @current_value = skipt
      @transformers = trs
      @listeners = []
      @description = false
    end

    def subscribe(&blk)
      subscription = Subscription.new(self, &blk)
      register(subscription)
      subscription
    end

    def link(*transformers)
      # like links in a #chain
      built_link = Observable.new(*transformers.flatten)
      register built_link
      built_link
    end

    def register(listener)
      @listeners << listener
    end

    def next(next_value)
      self.current_value = transformers.reduce(result(next_value)) do |iter_result, transformer|
        break iter_result if iter_result.skipt
        transformer.call(iter_result.value)
      end
      unless current_value.skipt
        @listeners.each do |listener|
          listener.next(current_value.value)
        end
      end
    end

    def chain(*chained_transformers)
      link(*chained_transformers)
    end
  end

  module Transformers
    class Idempotent
      include Helpers
      def call(next_value)
        result(next_value)
      end
    end

    class Map
      include Helpers
      attr_reader :mapper

      def initialize &blk
        @mapper = blk
      end

      def call(next_value)
        result(mapper.call(next_value))
      end
    end

    class Pair
      include Helpers
      attr_reader :mapper, :prev

      def initialize(&blk)
        @mapper = blk
        @prev = nil
      end

      def call(next_value)
        @prev = mapper.call(next_value, @prev)
        result(prev)
      end
    end

    class Filter
      include Helpers
      attr_reader :filterer

      def initialize &blk
        @filterer = blk
      end

      def call(next_value)
        if filterer.call(next_value)
          result next_value
        else
          skipt
        end
      end
    end

    class Last
      include Helpers
      attr_reader :count

      def initialize(count, fill)
        @count = count
        @buffer = fill
      end

      def call(next_value)
        @buffer.unshift(next_value)
        @buffer.pop if @buffer.count > count
        if @buffer.count == count
          result(@buffer)
        else
          skipt
        end
      end
    end

    class WithLatestFrom
      include Helpers
      attr_accessor :non_triggeringsß
      attr_reader :latests

      def initialize(*non_triggerings¢)
        @latests = non_triggerings¢.count.times.map { skipt }
        self.non_triggeringsß = non_triggerings¢.map.with_index do |non_triggering¢, i|
          @latests[i] = non_triggering¢.current_value #unless non_triggering¢.current_value&.skipt
          non_triggering¢.subscribe do |latest|
            latests[i] = result(latest)
          end
        end
      end

      def call(next_value)
        if latests.none?(&:skipt)
          return result([next_value].concat(latests.map(&:value)))
        end
        skipt
      end
    end

    class Wait
      include Helpers

      def initialize(until›)
        @until_called = false
        until›.subscribe do |_happened|
          @until_called = true
        end
      end

      def call(next_value)
        return skipt unless @until_called
        result(next_value)
      end
    end
  end

  class ConcatMap
    include Helpers
    extend Helpers

    attr_accessor :sourcesß, :sources

    def self.build(*sources›)
      concat_map_inst = new(sources›)

      downstream = observable(concat_map_inst)
      sourcesß = sources›.map do |source›|
        source›.register(downstream)
      end
      concat_map_inst.sourcesß = sourcesß
      downstream
    end

    def initialize(sources)
      @sources = sources
    end

    def call(_next_value)
      result(sources.map do |v›|
        v›.current_value.value unless v›.current_value.skipt
      end)
    end
  end

  class ConcatHash
    include Helpers
    extend Helpers

    attr_accessor :sourcesß, :sources_hash

    def self.build(**sources›)
      concat_map_inst = new(sources›)

      downstream = observable(concat_map_inst)
      sourcesß = sources›.map do |_k, source›|
        source›.register(downstream)
      end
      concat_map_inst.sourcesß = sourcesß
      downstream
    end

    def initialize(sources_hash)
      @sources_hash = sources_hash
    end

    def call(_next_value)
      result(sources_hash.filter_map do |(k, v)|
        [k, v.current_value.value] unless v.current_value.skipt
      end.to_h)
    end
  end

  module Helpers
    def idempotent; Transformers::Idempotent.new; end
    module_function :idempotent

    def observable(transformer = idempotent); Observable.new(transformer); end
    module_function :observable

    def filter(&blk)
      Transformers::Filter.new(&blk)
    end
    module_function :filter

    def map(&blk)
      Transformers::Map.new(&blk)
    end
    module_function :map

    def last(count, fill = [])
      Transformers::Last.new(count, fill)
    end
    module_function :last

    def with_latest_from(*non_triggerings¢)
      Transformers::WithLatestFrom.new(*non_triggerings¢)
    end
    module_function :with_latest_from

    def concat_map(*sources¢)
      ConcatMap.build(*sources¢)
    end
    module_function :concat_map

    def concat_hash(**sources›)
      ConcatHash.build(**sources›)
    end
    module_function :concat_hash

    def merge(*sources¢)
      merged = observable
      sources¢.each { |source¢| source¢.register(merged) }
      merged
    end
    module_function :merge

    def changed(field = nil)
      filterer = if field
        filter { |(current, prev)| current != prev && current.send(field) != current.send(field) }
      else
        filter { |(current, prev)| current != prev }
      end
      [
        last(2, [nil, nil]),
        filterer,
        map { |(current, _prev)| current }
      ]
    end
    module_function :changed

    def gate(must›)
      [
        with_latest_from(must›),
        filter { |(_it, must)| must },
        map { |it, _must| it }
      ]
    end
    module_function :gate

    def wait(until›)
      Transformers::Wait.new(until›)
    end
    module_function :wait

    def pair(&blk)
      Transformers::Pair.new(&blk)
    end
    module_function :pair
  end
end
