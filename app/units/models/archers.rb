module Units
  module Archers
    module Sheet
      include HasIcon
      IDLE_SHEET_ROW = 6
      IDLE_SHEET_FRAMES = 6
      FACTION = :knights
      MODEL = :archer

      def model; MODEL; end
      def path; Helpers.troop_sheet(FACTION, MODEL, color); end
      def offset; vec2(80, 64).with_f; end
      def dimensions; vec2(3*TILE_SIZE, 3*TILE_SIZE); end

      def animation_configs
        {
          idle: { row: 6, frame_count: 6, frame_duration: 6 },
          walk: { row: 5, frame_count: 6, frame_duration: 6 },
          shoot: { frame_count: 8, frame_duration: 4 }
        }
      end

      private

      attr_reader :color
    end

    class Archer
      include VP::Helpers
      include GridPositioning
      include Units::Animated
      include Units::Archers::Sheet
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

      def selectbox
        hurtbox
      end
    end

    def build_asset_options
      AssetOptionFactory.build_colors(Sheet, icon_offset: vec2(60, 56), icon_size: vec2(90, 75))
    end
    module_function :build_asset_options
  end
end
