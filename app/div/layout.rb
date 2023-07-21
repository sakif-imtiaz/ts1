module Layout
  include ::VP::Helpers

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
    def initialize(w, h)
      @w, @h = w, h
    end

    def against(_position, dimensions)
      w_against = w.against(dimensions.w)
      h_against = h.against(dimensions.h)
      vec2(w_against, h_against)
    end
  end

  class Bounds
    attr_reader :offset, :size

    def initialize(offset = Layout::Helpers.offset, size = Layout::Helpers.size)
      @offset, @size = offset, size
    end

    def x; offset.x; end
    def y; offset.y; end
    def w; size.w; end
    def h; size.h; end

    def x=(other); offset.x = other; end
    def y=(other); offset.y = other; end
    def w=(other); size.w = other; end
    def h=(other); size.h = other; end
  end

  class Anchor
    BOTTOM_LEFT = [0, 0]
    TOP_LEFT = [0, 1]
    BOTTOM_RIGHT = [1, 0]
    TOP_RIGHT = [1, 1]

    def self.bottom_left; BOTTOM_LEFT; end
    def self.top_left; TOP_LEFT; end
    def self.bottom_right; BOTTOM_RIGHT; end
    def self.top_right; TOP_RIGHT; end

    def self.default; bottom_left; end
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

  # class Bounds
  #   attr_accessor :position, :dimensions, :shrink_wrapped, :anchor
  #
  #   def initialize(position:, dimensions:, shrink_wrapped:, anchor:)
  #     @position, @dimensions, @shrink_wrapped, @anchor =
  #       position, dimensions, shrink_wrapped, anchor
  #   end
  #
  #   def to_s
  #     { x: x.to_s, y: y.to_s, w: w.to_s, h: h.to_s, shrink_wrapped: shrink_wrapped, anchor: anchor}.to_s
  #   end
  #
  #   def clone
  #     self.class.new(position: position.clone, dimensions: dimensions.clone, shrink_wrapped: shrink_wrapped.clone, anchor: anchor.clone)
  #   end
  #
  #   def x; position.x; end
  #   def y; position.y; end
  #   def w; dimensions.w; end
  #   def h; dimensions.h; end
  #
  #   def x=(other_x); position.x = other_x; end
  #   def y=(other_y); position.y = other_y; end
  #   def w=(other_w); dimensions.w = other_w; end
  #   def h=(other_h); dimensions.h = other_h; end
  #
  #   def against(vp_rect)
  #     x_against = x.against(vp_rect.w)
  #     y_against = y.against(vp_rect.h)
  #     w_against = w.against(vp_rect.w)
  #     h_against = h.against(vp_rect.h)
  #
  #     x_anchored = anchor[0]*(vp_rect.w - 2*x_against - w_against) + vp_rect.x + x_against
  #     y_anchored = anchor[1]*(vp_rect.h - 2*y_against - h_against) + vp_rect.y + y_against
  #     calculated_rect_params = [
  #       x_anchored,
  #       y_anchored,
  #       w_against,
  #       h_against
  #     ]
  #     quick_rect(*calculated_rect_params)
  #   end
  # end
  #
  # class RxBounds
  #   attr_reader :bounds›, :bounds, :hidden
  #
  #   def initialize(bounds)
  #     @hidden = false
  #     @bounds = bounds
  #     @bounds› = Pushy::Observable.new
  #   end
  #
  #   def hide!
  #     return if hidden
  #     @hidden = true
  #     emit!
  #   end
  #
  #   def unhide!
  #     return unless hidden
  #     @hidden = false
  #     emit!
  #   end
  #
  #   def bounds_or_hidden
  #     if hidden
  #       Helpers.hidden_bounds
  #     else
  #       @bounds
  #     end
  #   end
  #
  #   def emit!
  #     @bounds›.next(bounds_or_hidden)
  #   end
  #
  #   # doesn't seem to make sense here, it doesn't tell you how to calculate the rect
  #   # it has to do with how something else calculates the rect
  #   def shrink_wrapped=(other_value)
  #     @bounds.shrink_wrapped = other_value
  #     emit!
  #   end
  #
  #   def anchor=(other_anchor)
  #     @bounds.anchor = other_anchor
  #     emit!
  #   end
  #
  #   def bounds=(other_bounds)
  #     @bounds = other_bounds
  #     emit!
  #   end
  #
  #   def position=(other_position)
  #     @bounds.position = other_position
  #     emit!
  #   end
  #
  #   def dimensions=(other_dimensions)
  #     @bounds.dimensions = other_dimensions
  #     emit!
  #   end
  #
  #   def x=(other_x)
  #     @bounds.x = other_x
  #     emit!
  #   end
  #
  #   def y=(other_y)
  #     @bounds.y = other_y
  #     emit!
  #   end
  #
  #   def w=(other_w)
  #     @bounds.w = other_w
  #     emit!
  #   end
  #
  #   def h=(other_h)
  #     @bounds.h = other_h
  #     emit!
  #   end
  # end

  module Helpers
    def offset(xa = nil, ya = nil, x: nil, y: nil)
      xp = x || xa
      yp = y || ya
      Bounds.new(
        Offset.new(
          Length.parse(xp) || xp || px(0),
          Length.parse(yp) || xp || px(0)
        ),
        Size.new(percent(100), percent(100))
      )
    end

    def size(wa = nil, ha = nil, w: nil, h: nil)
      wp = w || wa
      hp = h || ha
      Bounds.new(
        Offset.new(px(0),px(0)),
        Size.new(
          Length.parse(wp) || wp || percent(100),
          Length.parse(hp) || hp || percent(100)
        )
      )
    end

    def length(percent: 0, pixels: 0)
      Length.length(percent: percent, pixels: pixels)
    end

    def percent(v); Length.percent(v); end
    def px(v); Length.px(v); end
    def quick_bounds(xa_or_rect = nil, ya = nil, wa = nil, ha = nil, **sparams)
      params = sparams.clone
      params.merge(xa_or_rect.to_h) if xa_or_rect.is_a?(VP::Rect)
      x = Length.parse(params[:x]) || Length.parse(xa_or_rect) || params[:x] || xa_or_rect || px(0)
      y = Length.parse(params[:y]) || Length.parse(ya) || params[:y] || ya || px(0)
      w = Length.parse(params[:w]) || Length.parse(wa) || params[:w] || wa || percent(100)
      h = Length.parse(params[:h]) || Length.parse(ha) || params[:h] || ha || percent(100)
      Bounds.new(
        Offset.new(x, y),
        Size.new(w, h),
        # shrink_wrapped: params[:shrink_wrapped] || false,
        # anchor: params[:anchor] || bottom_left
      )
    end

    module_function :offset, :size, :length, :percent, :px, :quick_bounds

    def bottom_left; Anchor.bottom_left; end
    def top_left; Anchor.top_left; end
    def bottom_right; Anchor.bottom_right; end
    def top_right; Anchor.top_right; end

    module_function :bottom_left, :top_left, :bottom_right, :top_right

    def hidden_bounds
      quick_bounds(x: -1, y: -1, w: 0, h: 0)
    end
    module_function :hidden_bounds
  end
end