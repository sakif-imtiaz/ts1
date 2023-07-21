module Units
  module Trees
    module Sheet
      include HasIcon

      def model; :tree; end

      def path
        "assets/tiny_swords/Resources/Trees/Tree.png"
      end

      def animation_configs
        {
          idle: { row: 2, frame_count: 4, frame_duration: 6 },
          whacked: { row: 1, frame_count: 2, frame_duration:  6 },
          stump: { row: 0, frame_count: 1, frame_duration:  1 },
        }
      end

      def offset; vec2(1.5*TILE_SIZE - 16, 14).with_f; end
      def dimensions; vec2(3*TILE_SIZE, 3*TILE_SIZE); end
    end

    class Tree
      include VP::Helpers
      include GridPositioning
      include Units::Trees::Sheet
      include Units::Animated
      include Units::Health

      def initialize(board_position)
        self.board_position = board_position
      end

      def expired?
        false
      end

      def hurtbox
        rect(board_position, vec2(32,64))
      end

      # def offset
      #   current_action&.offset
      # end

      def idle!
        action_queue.push Idle.new(self)
      end

      def board_primitives
        super + collider_primitives + health_bar
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
    end

    def build_asset_options
      [
        AssetOptionFactory.build(Sheet, icon_offset: vec2(32, 16), icon_size: vec2(128, 176))
      ]
    end
    module_function :build_asset_options
  end
end
