module VP
  class Border
    include Arby::Attributes
    include Bounded
    include Colored
    include Util

    attr_reader :blendmode_enum

    def initialize(**kwargs)
      assign!(**kwargs)
    end

    def primitive_marker
      :border
    end

    def to_h
      %i[primitive_marker x y w h r g b a].map { |k| [k, send(k) ]}.to_h
    end
  end

  module Helpers
    def hollow_solid(**kwargs)
      Border.new(**kwargs)
    end
    module_function :hollow_solid
  end
end
