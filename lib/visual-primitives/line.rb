module VP
  class Line
    include Arby::Attributes
    include Bounded
    include Colored
    include Util

    attr_accessor :blendmode_enum

    def initialize(**kwargs)
      assign!(**kwargs)
    end

    def x1; x; end
    def y1; y; end
    def x2; x + w; end
    def y2; y + h; end

    def primitive_marker
      :line
    end

    def to_h
      %i[primitive_marker x1 x2 y1 y2 r g b a].map { |k| [k, send(k) ]}.to_h
    end
  end

  module Helpers
    def line(**kwargs)
      Line.new(**kwargs)
    end
    module_function :line
  end
end
