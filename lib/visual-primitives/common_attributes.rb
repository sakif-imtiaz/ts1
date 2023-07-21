module VP
  module Positioned
    # when mixing this in, you are expected to have `attr_reader :position`

    # TODO: Handle Triangle
    attr_reader :x2, :y2, :x3, :y3

    def x; position.x; end
    def y; position.y; end
    def x=(o); position.x = o; end
    def y=(o); position.y = o; end
  end

  module Dimensioned
    def w; dimensions.x; end
    def h; dimensions.y; end
    def w=(o); dimensions.x = o; end
    def h=(o); dimensions.y = o; end
  end

  module Bounded
    include Positioned
    include Dimensioned
    attr_writer :bounds

    # TODO: this should be someplace meant for all primitives
    def renderables
      [self]
    end

    def bounds
      @bounds ||= quick_rect(nil, nil, nil, nil)
    end

    def position
      bounds.position
    end

    def position=(other)
      bounds.position = other
    end

    def dimensions
      bounds.dimensions
    end

    def dimensions=(other)
      bounds.dimensions = other
    end

    def current_rect
      bounds
    end

    # def place!(parent_rect:, _current_bounds: nil)
    #   assign!(**parent_rect.to_h)
    # end

    def place!(parent_rect)
      assign!(**parent_rect.to_h)
    end
  end

  module Util
    def data
      @_data ||= {}
    end

    attr_writer :layer

    def layer
      @layer ||= 0
    end
  end

  class Rect
    include Positioned
    include Dimensioned
    attr_writer :position, :dimensions

    def initialize(position:, dimensions:)
      @position, @dimensions = position, dimensions
    end

    def position
      @position ||= point(nil, nil)
    end

    def dimensions
      @dimensions ||= point(nil, nil)
    end

    def offset!(offset)
      @position.offset!(offset)
      self
    end

    def self.null
      new(position: point(nil,nil), dimensions: point(nil, nil))
    end

    def clone
      self.class.new(position: position.clone, dimensions: dimensions.clone)
    end

    def self.from_h(x:, y:, w:, h:)
      new(position: point(x, y), dimensions: point(w, h))
    end

    def to_h
      # position.to_h.merge({ w: w, h: h })
      {x: x, y: y, w: w, h: h}
    end

    def inside_rect?(other_rect)
      cr = canonical
      [cr.p1, cr.p2].all? { |p| p.inside_rect?(other_rect) }
    end

    def merge(other_rect)
      cr, corect = canonical, other_rect.canonical
      nx = [cr.x, corect.x].min
      ny = [cr.y, corect.y].min
      quick_rect(
        nx,
        ny,
        [cr.p2.x, corect.p2.x].max - nx,
        [cr.p2.y, corect.p2.y].max - ny
      )
    end

    def stretch!(by); @dimensions += by; self; end
    def stretch(by); build.stretch!(by); end
    def nudge(offset); build.nudge!(offset); end
    def nudge!(offset); @position += offset; self; end

    def p1
      position
    end

    def p2
      point(x+w, y+h)
    end

    def canonical
      c_x, c_x_w = [x, x + w].sort
      c_y, c_y_h = [y, y + h].sort

      build(point(c_x, c_y), point(c_x_w - c_x, c_y_h - c_y))
    end

    def intersect_rect?(rect)
      to_h.intersect_rect?(rect.to_h)
    end

    def build(pos = position, dim = dimensions)
      Rect.new(position: pos, dimensions: dim)
    end

    def with_f
      build(position.with_f, dimensions.with_f)
    end

    def with_i
      build(position.with_i, dimensions.with_i)
    end

    def ==(other)
      other && (to_h == other.to_h)
    end

    alias_method :eql?, :==

    def inspect
      to_s
    end

    def serialize
      to_h
    end

    def to_s
      to_h.to_s
    end
  end

  module Colored
    # when mixing this in, you are expected to *NOT* have `attr_reader :color`
    # and just set @color

    def r; color.r; end
    def g; color.g; end
    def b; color.b; end
    def a; color.a; end

    def color
      @color ||= Color.default
    end

    def color=(the_color)
      if the_color.is_a?(Color)
        @color = the_color.clone
      elsif the_color.is_a?(String) || the_color.is_a?(Symbol)
        @color = Helpers.color(the_color).clone
      end
    end
  end

  module Renderable
    def renderables(**kwargs)
      assign!(**kwargs)
      self
    end
  end
end
