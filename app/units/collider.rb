module Units
  module Colliders
    module Collider
      attr_reader :unit

      def red
        VP::Color.new([255, 0, 0, 100])
      end

      def aqua
        VP::Color.new([0,255,255, 100])
      end

      def color
        raise "need a color for this, pal"
      end

      def primitives
        [VP::Helpers.solid(color: color, bounds: box)]
      end

      def perform!(other_unit)
        nil
      end

      def party
        unit.party
      end
    end

    class Hurt
      include Collider

      def color
        aqua
      end

      def initialize(unit)
        @unit = unit
      end

      def box
        unit.hurtbox
      end
    end

    class SlashHit
      include Collider

      def color
        red
      end

      def initialize(unit, slash)
        @unit, @slash, @already_hit = unit, slash, []
      end

      def perform!(other_unit)
        hurt = other_unit&.colliders&.hurt
        return unless hurt
        hit!(other_unit) if check?(hurt)
      end

      def box
        slash.hitbox
      end

      private

      attr_reader :slash, :already_hit

      def hit!(other_unit)
        already_hit << other_unit
        other_unit.health -= 5.0 # maybe this should be in Hurt collider
      end

      def check?(hurt)
        not_hit?(hurt) && enemy?(hurt) && hurt.box && intersect?(hurt)
      end

      def not_hit?(hurt)
        !(already_hit.include?(hurt.unit))
      end

      def enemy?(hurt)
        hurt.party != unit.party
      end

      def intersect?(hurt)
        box.intersect_rect?(hurt.box)
      end
    end

    class Chop < SlashHit
      def hit!(other_unit)
        puts "chopping!"
        super
        other_unit.start!(Units::Whacked.new(other_unit))
      end

      def check?(hurt)
        not_hit?(hurt) && tree?(hurt) && hurt.box && intersect?(hurt)
      end

      def tree?(hurt)
        hurt.unit.model == :tree
      end
    end

    class ArrowHit
      include Collider

      def color
        red
      end

      def initialize(unit)
        @unit, @flying = unit, true
      end

      def perform!(other_unit)
        hurt = other_unit&.colliders&.hurt
        hit!(other_unit) if check?(hurt)
      end

      def box
        rect(
          (arrow.board_position),
          vec2(10, 10)
        )
      end

      private

      def arrow
        unit
      end

      def hit!(other_unit)
        @flying = false
        other_unit.health -= 5.0 # maybe this should be in Hurt collider
        Units.manager.units.delete unit
      end

      def check?(hurt)
        flying? && enemy?(hurt) && hurt.box && intersect?(hurt)
      end

      def flying?
        @flying
      end

      def enemy?(hurt)
        hurt.party != arrow.party
      end

      def intersect?(hurt)
        box.intersect_rect?(hurt.box)
      end
    end
  end
end
