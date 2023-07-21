module Units
  module Arrows

    module Sheet
      def path
        "assets/tiny_swords/Factions/Knights/Troops/Archer/Arrow/Arrow.png"
      end

      def animation_configs
        {
          stuck: { row: 0, frame_count: 1, frame_duration: 1 },
          fly: { row: 1, frame_count: 1, frame_duration: 1 },
        }
      end

      # def offset; vec2(0, 34).with_f; end
      def dimensions; vec2(TILE_SIZE, 1*TILE_SIZE); end
      def pivot; offset + vec2(TILE_SIZE, 0); end
    end

    class Arrow
      include VP::Helpers
      include Units::Animated
      include Units::Arrows::Sheet

      attr_accessor :board_position, :shot_by

      def initialize(board_position, shot_by)
        @board_position = board_position
        @shot_by = shot_by
      end

      def party
        shot_by.party
      end

      def expired?
        current_action.is_a?(StuckArrow)
      end

      def offset
        current_action&.offset
      end

      def idle!
        action_queue.push StuckArrow.new(self, shot_by)
      end

      def hitbox_solid
        [(solid(color: VP::Color.new([255, 0, 0, 100]), bounds: hitbox) if hitbox)]
      end

      def board_primitives
        super + collider_primitives
      end

      def hitbox
        current_action&.hitbox
      end

      def selectbox
        nil
      end

      # colliders

      def collider_primitives
        # candidate for module
        # rv =
        colliders.values.compact.map(&:primitives).reduce([], :+)
        # puts colliders.values.compact.map(&:primitives).reduce(:+).inspect if rv.nil?
        # rv
      end

      def colliders
        { hit: current_action&.colliders.hit }
      end
    end
  end
end