require 'matrix'

class Dimensions
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

  def clamp(rect)
    vec2(
      x.clamp(rect.x, rect.w + rect.x),
      y.clamp(rect.h, rect.h + rect.h),
      )
  end
end

class Point < Dimensions
  def to_h
    { w: w, h: h }
  end
end

class Asset
  attr_reader :dimensions
  def initialize(dims)
    @dimensions = dims
  end
end

module MatrixFunctions
  def vec2(a,b)
    Point.new(Vector[a,b])
  end
end

def dimensions(a, b)
  # Dimensions.new()
  vec2(a,b)
end

require "./lib/arby/arby.rb"
require "./lib/visual-primitives/basic_values.rb"
require "./lib/visual-primitives/common_attributes.rb"
require "./lib/visual-primitives/label.rb"
require "./lib/visual-primitives/solid.rb"
require "./lib/visual-primitives/sprite.rb"
require "./lib/visual-primitives/border.rb"
