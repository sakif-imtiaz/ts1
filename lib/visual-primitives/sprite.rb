module VP
  module Sprites
    class Source
      include Bounded
      attr_writer :bounds

      def initialize(bounds:)
        @bounds = bounds
      end

      def bounds
        @bounds ||= Rect.null
      end

      def self.default
        new(bounds: VP::Rect.new(position: point(nil,nil), dimensions: point(nil,nil)))
      end
    end

    module Sourced
      # TODO: Handle Triangle
      attr_reader :source_x2, :source_y2, :source_x3, :source_y3
      attr_writer :source

      def source; @source ||= Source.default; end
      def source_x; source.x; end
      def source_x=(z); source.x = z; end
      def source_y; source.y; end
      def source_y=(z); source.y = z; end
      def source_w; source.w; end
      def source_w=(z); source.w = z; end
      def source_h; source.h; end
      def source_h=(z); source.h = z; end
    end

    class Tile
      include Bounded
      attr_accessor :bounds

      def initialize(bounds:)
        @bounds = bounds
      end

      def self.default
        new(bounds: VP::Rect.new(position: point(nil,nil), dimensions: point(nil,nil)))
      end
    end

    module Tiled
      attr_writer :tile
      def tile; @tile ||= Tile.default; end

      # TODO: Handle Triangle
      attr_reader :tile_x2, :tile_y2, :tile_x3, :tile_y3

      def tile_x; tile.x; end
      def tile_y; tile.y; end
      def tile_w; tile.w; end
      def tile_h; tile.h; end
    end

    class Rotation
      include Positioned
      attr_accessor :position

      attr_accessor :flip_horizontally, :flip_vertically, :angle

      def initialize(position: point(nil, nil), flip_vertically: false, flip_horizontally: false, angle: nil)
        @position, @flip_vertically, @flip_horizontally, @angle = position, flip_vertically, flip_horizontally, angle
      end

      def self.default
        new
      end
    end

    module Rotated
      attr_writer :rotation
      def rotation; @rotation || Rotation.default; end

      def angle_anchor_x; rotation.x; end
      def angle_anchor_y; rotation.y; end
      def angle; rotation.angle; end
      def flip_horizontally; rotation.flip_horizontally; end
      def flip_vertically; rotation.flip_vertically; end
    end
  end

  class Sprite
    include Arby::Attributes
    include Bounded
    include Colored
    include Util

    include Sprites::Sourced
    include Sprites::Tiled
    include Sprites::Rotated

    attr_accessor :blendmode_enum
    # attr_writer :path
    attr_accessor :path

    def initialize(**kwargs)
      assign!(**kwargs)
    end

    # def path
    #   if @path && @path.to_sym == @path && $gtk.args.rend
    #   end
    # end

    def primitive_marker
      :sprite
    end

    def to_h
      %i[
        primitive_marker path x y w h r g b a
        source_x source_y source_w source_h
        tile_x tile_y tile_w tile_h
        angle angle_anchor_x angle_anchor_x flip_horizontally flip_vertically
      ].map { |k| [k, send(k) ]}.to_h
    end
  end

  module Helpers
    def sprite(**kwargs)
      Sprite.new(**kwargs)
    end
    module_function :sprite
  end
end
