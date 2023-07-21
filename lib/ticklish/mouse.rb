module Services
  def mouse
    @@mouse_instance ||= Mouse::Provider.new
  end
  module_function :mouse

  module Mouse
    class ButtonState
      attr_reader :state, :changed, :button

      def initialize(state, button, changed = false)
        @state, @changed = state, changed
        @button = button
      end

      def down?; state; end
      def up?; !state; end

      def changed?; changed; end

      def inspect; to_s; end
      def to_s; to_h.to_s; end
      def to_h; {state: state, button: button, changed: changed}; end

      def left?; button == :left; end
      def middle?; button == :middle; end
      def right?; button == :right; end
    end

    class MouseAction
      include Arby::Attributes
      attr_reader :x, :y, :left, :right, :middle, :tick
      def initialize(x:, y:, tick:, left: nil, right: nil, middle: nil)
        @x, @y = x, y
        @tick = tick
        @left, @right, @middle = left, right, middle
      end

      def w
        0
      end

      def h
        0
      end

      def to_h
        slice(*%i(x y w h left middle right))
      end

      def point
        vec2(x, y).not_dim!
      end

      def to_s
        to_h.to_s
      end

      def button_states
        [left, right, middle]
      end

      def up
        [left, right, middle].find do |button|
          button&.up? && button.changed?
        end
      end

      def down
        [left, right, middle].find do |button|
          button&.down? && button.changed?
        end
      end

      def button_change?
        up || down
      end

      def one_down
        just_pushed_down = button_states.select { |button| button&.down? && button.changed? }
        if just_pushed_down.one?
          just_pushed_down.first
        else
          false
        end
      end

      def any_button_held_down?
        [left, right, middle].any? do |button|
          button&.down? && !button.changed?
        end
      end
    end

    class DragEvent
      attr_reader :ma, :stage
      def initialize(ma, stage)
        @ma, @stage = ma, stage
      end

      def start?; stage == :start; end
      def move?; stage == :move; end
      def end?; stage == :end; end

      def to_s
        to_h.to_s
      end

      def to_h
        { ma: ma.to_h, stage: stage }
      end
    end

    def self.point(*args, **kwargs)
      Layout::Position.new(*args, **kwargs)
    end

    class Drag
      attr_reader :stage, :p1, :p2, :rect, :button
      def initialize(event, p1: nil, button: nil)
        @stage = event.stage
        @p2 = point(event.ma.x, event.ma.y)
        @p1 = p1 || @p2
        @rect = VP::Helpers.quick_rect(@p1.x, @p1.y, @p2.x - @p1.x, @p2.y - @p1.y)
        @button = button || event.ma.one_down
      end

      def summarize
        puts "@button.inspect #{@button.inspect}  |  stage #{@stage}"
      end

      def to_h
        { stage: stage, button: button }
      end

      def next(event)
        return Drag.new(event) if event.start?
        Drag.new(event, p1: p1.clone, button: button.clone)
      end

      def left?; button && button.left?; end
      def right?; button && button.right?; end
      def middle?; button && button.middle?; end

      def start?; stage == :start; end
      def move?; stage == :move; end
      def end?; stage == :end; end
    end

    class Click
      attr_reader :up, :down
      def initialize(up:, down:)
        @up, @down = up, down
      end

      def within?(rect)
        up.to_h.inside_rect?(rect) &&
          down.to_h.inside_rect?(rect)
      end

      def tick
        up.tick
      end

      def inspect
        to_s
      end

      def to_h
        { up: up.to_h, down: down.to_h }
      end

      def to_s
        to_h.to_s
      end

      def left?
        up.left.changed? && down.left.changed?
      end

      def right?
        up.right.changed? && down.right.changed?
      end
    end

    class ClickTransformer
      include Pushy::Helpers

      def initialize
        @down = nil
      end

      def call(next_value)
        if @down.nil?
          @down = next_value if next_value.down
        elsif next_value.up && next_value.up.button == @down.down.button
          temp_down = @down
          @down = nil
          return result Click.new(down: temp_down, up: next_value)
        else
          @down = nil
        end
        skipt
      end
    end

    class Provider
      # include ::Pushy::Transformers
      include Pushy::Helpers
      attr_reader :args

      def tick(args)
        @args = args
        produce_raw!
      end

      def produce_raw!
        mouse = args.inputs.mouse
        raw.next(
          {
            x: mouse.x,
            y: mouse.y,
            left: mouse.button_left,
            right: mouse.button_right,
            middle: mouse.button_middle,
            tick: args.state.tick_count
          }
        )
      end

      def raw
        @raw ||= Pushy::Observable.new
      end

      def clicks›
        @clicks ||= presses.chain(
          ClickTransformer.new
        )
      end

      def mouse_actions
        @_mouse_actions ||= raw.chain(
          last(2),
          map do |last2|
            current, prev = *last2
            states = [:left, :right, :middle].reduce({}) do |diff, btn|
              diff[btn] = ButtonState.new(current[btn], btn, current[btn] != prev[btn])
              diff
            end
            MouseAction.new(x: current[:x], y: current[:y], tick: current[:tick], **states)
          end
        )
      end

      def presses
        @presses ||= mouse_actions.link(
          filter { |mouse_action| mouse_action.button_change? }
        )
      end

      module ProvidingDrag

        def drag_events›
          @_drag_events› ||= merge(drag_end›, drag_start›, drag_move›)
        end

        def drag›
          @_drag› ||= drag_events›.link(
            pair do |curr_event, prev_drag|
              if prev_drag
                raise "should be a drag" unless prev_drag.is_a?(Drag)
                raise "should be a DragEvent" unless curr_event.is_a?(DragEvent)
                prev_drag.next(curr_event)
              else
                Drag.new(curr_event)
              end
            end,
            last(2),
            filter do |(curr, prev)|
              if prev.end?
                curr.start?
              elsif prev.move?
                curr.move? || curr.end?
              elsif prev.start?
                curr.move?
              end
            end,
            map { |(curr, _prev)| curr }
          )
        end

        def drag_start›
          @_drag_start› ||= mouse_actions.chain(
            filter { |ma| ma.button_change? && ma.one_down },
            map { |ma| DragEvent.new(ma, :start) }
          )
        end

        def drag_move›
          @_drag_move› ||= mouse_actions.chain(
            filter { |ma| !(ma.button_change?) && ma.any_button_held_down? },
            map { |ma| DragEvent.new(ma, :move) }
          )
        end

        def drag_end›
          @_drag_end› ||= mouse_actions.chain(
            filter { |ma| ma.button_change? },
            map { |ma| DragEvent.new(ma, :end) }
          )
        end
      end

      include ProvidingDrag
    end
  end
end