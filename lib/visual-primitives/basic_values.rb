include MatrixFunctions

module VP
=begin
  class Point
    attr_accessor :x, :y

    def initialize(vec = nil, x: nil, y: nil)
      if vec
        @x, @y = vec.x, vec.y
      else
        @x, @y = x, y
      end
    end

    # def to_vec
    #   vec2(x, y)
    # end
    #
    # def binary(other)
    #   self.class.new(yield to_vec, other.to_vec)
    # end
    #
    # def with_constant(c)
    #   self.class.new(yield to_vec, c)
    # end

    def w; x; end
    def h; y; end
    def w=(ow); @x = ow; end
    def h=(oh); @y = oh; end

    def +(other); new(x: x + other.x, y: y + other.y); end
    def -(other); new(x: x - other.x, y: y - other.y); end
    def *(c); new(x: x * c, y: y * c); end
    def /(c); new(x: x / c, y: y / c); end

    def ==(other)
      x == other.x && y == other.y
    end

    alias_method :eql?, :==

    def hash
      [x, y].hash
    end
  end
=end

  class Color
    attr_reader :rgba, :name

    def initialize(rgba, name = '')
      @rgba = rgba
      @name = name
    end

    def self.default
      new([nil, nil, nil, nil])
    end

    def r; rgba[0]; end
    def g; rgba[1]; end
    def b; rgba[2]; end
    def a; rgba[3]; end

    def r=(v); rgba[0] = v; end
    def g=(v); rgba[1] = v; end
    def b=(v); rgba[2] = v; end
    def a=(v); rgba[3] = v; end

    def to_h
      r, g, b, a = rgba[0], rgba[1], rgba[2], rgba[3]
      { r: r, g: g, b: b, a: a }
    end

    def darken(proportion)
      vals = rgba.map { |v| (v * proportion).clamp(0, 255).to_i }
      vals[3] = rgba[3]
      self.class.new(vals)
    end

    def darken!(proportion)
      a = rgba[3]
      rgba.map! { |v| v * proportion }
      rgba[3] = a
    end

    def inspect
      name
    end

    def clone
      self.class.new([r.clone, g.clone, b.clone, a.clone], name)
    end

    def ==(other)
      rgba == other.rgba
    end

    NIL        = new([nil, nil, nil, nil], :nil)
    DARK_GRAY   = new([25, 25, 25, 255], :dark_gray)
    RED         = new([255, 0, 0, 255], :red)
    LIME        = new([0, 255, 0, 255], :lime)
    BLUE        = new([0, 0, 255, 255], :blue)
    YELLOW      = new([255, 255, 0, 255], :yellow)
    CYAN        = new([0, 255, 255, 255], :cyan)
    FUCHSIA     = new([255, 0, 255, 255], :fuchsia)
    WHITE       = new([255, 255, 255, 255], :white)

    def self.colors
      @@colors ||= load_colors
    end

    def self.load_colors
      loaded_colors = {}
      File.open('config/web_colors.csv').readlines.each do |line|
        name, _fullname, _rgb, r, g, b = line.chomp.split(",")
        loaded_colors[name.to_sym] = Color.new([r,g,b,"255"].map(&:to_i), name.to_sym)
      end
      loaded_colors
    end
  end

  module Helpers
    def color(name)
      Color.colors[name]
    end

    def point(*a_p, x: nil, y: nil)
      if a_p.length == 0
        x = x
        y = y
      elsif a_p.length == 1
        x = a_p[0].x
        y = a_p[0].y
      elsif a_p.length == 2
        x = a_p[0]
        y = a_p[1]
      end
      # Point.new(vec2(x, y))
      vec2(x.try(:to_f), y.try(:to_f))
    end

    def build_dimensions(*a_d, w: nil, h: nil, x: nil, y: nil)
      if a_d.length == 0
        w = w || x
        h = h || y
      elsif a_d.length == 1
        w = a_d[0].x
        h = a_d[0].y
      elsif a_d.length == 2
        w = a_d[0]
        h = a_d[1]
      end
      # Point.new(vec2(w, h))
      vec2(w,h)
    end

    def quick_rect(x, y, w, h)
      created_quick_rect = VP::Rect.new(
        position: point(x, y),
        dimensions: build_dimensions(w, h)
      )
      created_quick_rect
    end

    def rect(pos, dims)
      VP::Rect.new(position: pos, dimensions: dims)
    end

    def vp_rect(position, dimensions)
      VP::Rect.new(position: position, dimensions: dimensions)
    end

    def zero_rect
      Rect.new(position: vec2(0, 0), dimensions: vec2(0, 0))
    end

    def window_rect
      Rect.new(position: vec2(0, 0), dimensions: vec2(1280, 720))
    end

    def window_dims
      vec2(1280, 720)
    end
  end
end


include VP::Helpers