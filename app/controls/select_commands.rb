module Inputs
  module DragCommands
    def handle(drag)
      route(drag).run!
    end
    module_function :handle

    def route(drag)
      if drag.left?
        selector = if held.shift?
                     Expand
                   elsif held.alt?
                     Toggle
                   else
                     Reselect
                   end
        SelectUnits.new(drag, selector)
      else
        NullCommand.new
      end
    end

    module_function :route

    def held
      Services.typing.held
    end

    module_function :held

    class Reselect
      def self.update_selection(units_within)
        Units.manager.selected.replace(units_within)
      end
    end

    class Toggle
      def self.update_selection(units_within)
        a1 = units_within
        a2 = Units.manager.selected
        Units.manager.selected.replace((a1 - a2) + (a2 - a1))
      end
    end

    class Expand
      def self.update_selection(units_within)
        Units.manager.selected.concat units_within
        Units.manager.selected.uniq!
      end
    end

    class SelectUnits
      def initialize(drag, selector)
        @drag = drag
        @selector = selector
      end

      def run!
        return unless contains_drag?
        if drag.end?
          update_selection!
          selection_widget.update_icons!
        end

        selection_widget.update_overlay!(drag)
      end

      def update_selection!
        selector.update_selection(Units.manager.units_within(drag.rect.canonical))
      end

      def contains_drag?
        selection_widget.contains_drag?(drag)
      end

      def selection_widget
        Units.selection_widget
      end

      private

      attr_reader :drag, :selector
    end
  end
end
