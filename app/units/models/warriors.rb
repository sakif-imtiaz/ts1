module Units
  module Warriors
    module Sheet
      include HasIcon
      FACTION = :knights
      MODEL = :warrior

      def model; MODEL; end
      def path
        @path ||= Helpers.troop_sheet(FACTION, MODEL, color)
      end

      def offset; vec2(86, 64).with_f; end
      def dimensions; vec2(3*TILE_SIZE, 3*TILE_SIZE); end

      def animation_configs
        {
          idle: { row: 7, frame_count: 6, frame_duration: 6 },
          walk: { row: 6, frame_count: 6, frame_duration: 6 },
          slash: { frame_count: 6, frame_duration: 6 }
        }
      end
    end

    class Warrior
      include VP::Helpers
      include GridPositioning
      include Units::Animated
      include Units::Warriors::Sheet
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

      def colliders
        super.merge({ hit: current_action&.colliders&.hit })
      end
    end

    def build_asset_options
      AssetOptionFactory.build_colors(Sheet, icon_offset: vec2(60, 56), icon_size: vec2(95, 90))
    end
    module_function :build_asset_options
  end
end
