
module Components
  include ::VP::Helpers
  module Lengths
    class Offset
      attr_accessor :x, :y
      def initialize(x, y)
        @x, @y = x, y
      end

      def against(position, dimensions)
        x_against = x.against(dimensions.w) + position.x
        y_against = y.against(dimensions.h) + position.y
        vec2(x_against, y_against)
      end
    end

    class Size
      attr_accessor :w, :h
      def initialize(w, h, padded: false)
        @w, @h = w, h
        @padding = padded
      end

      def padding?
        @padding
      end

      def against(_position, dimensions)
        w_against = w.against(dimensions.w)
        h_against = h.against(dimensions.h)
        vec2(w_against, h_against)
      end
    end

    class Length
      def against(primitive_length)
        from_percent = (primitive_length * percent / 100.0) || 0
        total = from_percent + pixels
        total
      end

      attr_accessor :percent, :pixels

      def initialize(percent = 0, pixels = 0)
        @percent, @pixels = percent, pixels
      end

      def ==(other)
        percent == other.percent &&
          pixels == other.pixels
      end

      alias_method :eql?, :==

      def hash
        [percent, pixels].hash
      end

      def pad(other)
        self/(other.percent/100.0) - other.pixels
      end

      def +(other)
        Length.new(percent + other.percent, pixels + other.pixels)
      end

      def -(other)
        Length.new(percent + -1 * other.percent, pixels + -1 * other.pixels)
      end

      def *(c)
        Length.new(percent * c, pixels * c)
      end

      def /(c)
        Length.new(percent/c, pixels/c)
      end

      def to_s
        "#{pixels}px #{percent}%"
      end

      def self.parse(str)
        return px(str) if str.is_a?(Numeric)
        return nil unless str.is_a?(String)
        sum = new
        str.split.each do |part|
          if part.end_with?("%")
            sum = sum + percent(part.chomp("%").to_f)
          elsif part.end_with?("px")
            sum = sum + px(part.chomp("px").chomp.to_f)
          else
            raise ArgumentError.new("Invalid length format")
          end
        end
        sum
      end

      def self.length(percent: 0, pixels: 0)
        new(percent, pixels)
      end

      def self.percent(v); length(percent: v); end
      def self.px(v); length(pixels: v); end
    end
  end


  module Helpers
    def offset(xa = nil, ya = nil, x: nil, y: nil)
      xp = x || xa
      yp = y || ya
      Lengths::Offset.new(
        Lengths::Length.parse(xp) || xp || px(0),
        Lengths::Length.parse(yp) || xp || px(0)
      )
    end

    def padding(*args, **kwargs)
      size(*args, padded: true, **kwargs)
    end

    def size(wa = nil, ha = nil, w: nil, h: nil, padded: false)
      wp = w || wa
      hp = h || ha
      Lengths::Size.new(
        Lengths::Length.parse(wp) || wp || percent(100),
        Lengths::Length.parse(hp) || hp || percent(100), padded: padded)
    end

    def length(percent: 0, pixels: 0)
      Length.length(percent: percent, pixels: pixels)
    end

    def percent(v); Lengths::Length.percent(v); end
    def px(v); Lengths::Length.px(v); end

    module_function :offset, :size, :length, :percent, :px

    # def bottom_left; Anchor.bottom_left; end
    # def top_left; Anchor.top_left; end
    # def bottom_right; Anchor.bottom_right; end
    # def top_right; Anchor.top_right; end
    #
    # module_function :bottom_left, :top_left, :bottom_right, :top_right

    # def hidden_bounds
    #   quick_bounds(x: -1, y: -1, w: 0, h: 0)
    # end
    # module_function :hidden_bounds
  end
end