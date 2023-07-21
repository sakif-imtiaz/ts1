require 'matrix'



module MatrixFunctions
  class Vec2
    attr_reader :vec
    def initialize(vec)
      @vec = vec
    end

    def x
      vec[0]
    end

    def w
      vec[0]
    end

    def h
      vec[1]
    end

    def y
      vec[1]
    end

    def to_s
      to_h.to_s
    end

    def to_h
      { x: x, y: y }
    end

    def ==(other)
      x == other.x && y ==other.y
    end

    def +(other)
      Vec2.new(Vector[x + other.x, y + other.y])
    end

    def *(other)
      Vec2.new(Vector[x * other, y * other])
    end

    def -(other)
      Vec2.new(Vector[x - other.x, y - other.y])
    end

    def manhattan_distance(v2)
      (y - v2.y).abs + (x - v2.x).abs
    end
  end

  def vec2(a,b)
    Vec2.new(Vector[a,b])
  end

  module_function :vec2
end

class Point < MatrixFunctions::Vec2
  attr_reader :vec

  def clamp(rect)
    vec2(
      x.clamp(rect.x, rect.w + rect.x),
      y.clamp(rect.h, rect.h + rect.h),
    )
  end
end

class Dimensions < Point
  def to_h
    { w: w, h: h }
  end
end



require "./lib/arby/arby_attributes.rb"
require "./lib/arby/arby.rb"

MatrixFunctions::Vec2.prepend(Arby::Vector2)

require "./lib/visual-primitives/basic_values.rb"
require "./lib/visual-primitives/common_attributes.rb"


