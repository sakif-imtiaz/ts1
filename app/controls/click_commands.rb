module Inputs
  module ClickCommands
    def handle(click)
      route(click).run!
    end
    module_function :handle

    def route(click)
      if click.up && click.up.right.changed?
        if held.is?(:a)
          Hit.new(vec2(click.up.x, click.up.y))
        else
          Walk.new(vec2(click.up.x, click.up.y))
        end
      else
        NullCommand.new
      end
    end

    module_function :route

    def held
      Services.typing.held
    end

    module_function :held

    class Walk
      attr_reader :to
      def initialize(to)
        @to = to
      end

      def cell_size
        Units::Navigation.cell_size
      end

      def run!
        Units.manager.selected.each do |unit|
          # grid_to = (to/cell_size).with_i
          field = $my_game.flow_field.build!(to)
          # $my_game.print_flow_field!(field)
          unit.enqueue_action!(Units::WalkPath.build(unit, field, to.snap(cell_size)))
        end
      end
    end

    class Hit
      HIT_ACTIONS = {
        Units::Archers::Archer => Units::Shoot,
        Units::Warriors::Warrior => Units::Slash,
        Units::Pawns::Pawn => Units::Chop
      }

      attr_reader :target
      def initialize(target)
        @target = target
      end

      def run!
        Units.manager.selected.each do |unit|
          hit_class = HIT_ACTIONS[unit.class]
          unit.enqueue_action!(hit_class.new(unit, target)) if hit_class
        end
      end
    end
  end
end
