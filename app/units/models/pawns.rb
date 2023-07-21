module Units
  module Pawns
    module Sheet
      include HasIcon
      FACTION = :knights
      MODEL = :pawn

      def model; MODEL; end
      def path; Helpers.troop_sheet(FACTION, MODEL, color); end
      def offset; vec2(84, 70).with_f; end
      def dimensions; vec2(3*TILE_SIZE, 3*TILE_SIZE); end

      def animation_configs
        {
          idle: { row: 5, frame_count: 6, frame_duration: 6 },
          walk: { row: 4, frame_count: 6, frame_duration: 6 },
          hammer: { row: 3, frame_count: 6, frame_duration: 4 },
          chop: { row: 2, frame_count: 6, frame_duration: 4 },
          carry_idle: { row: 1, frame_count: 6, frame_duration: 6 },
          carry_walk: { row: 0, frame_count: 6, frame_duration: 6 }
        }
      end

      private

      attr_reader :color
    end

    class Pawn
      include VP::Helpers
      include GridPositioning
      include Units::Animated
      include Units::Pawns::Sheet
      include Units::Health

      attr_accessor :color

      def initialize(board_position, color)
        self.board_position = board_position
        @color = color
      end

      def idle!
        action_queue.push Idle.new(self)
      end

      def board_primitives
        super + collider_primitives + health_bar
      end

      def hurtbox
        rect(board_position + vec2(72,66) - offset,
             vec2(48, 55)
        )
      end

      def selectbox
        hurtbox
      end

      def colliders
        super.merge({ hit: current_action&.colliders.hit })
      end
    end

    def build_asset_options
      AssetOptionFactory.build_colors(Sheet, icon_offset: vec2(60, 72), icon_size: vec2(78, 68))
    end
    module_function :build_asset_options
  end
end
