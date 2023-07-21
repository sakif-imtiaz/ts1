module VP
  class Solid
    include Arby::Attributes
    include Bounded
    include Colored
    include Util

    attr_accessor :blendmode_enum

    def initialize(**kwargs)
      assign!(**kwargs)
    end

    def primitive_marker
      :solid
    end

    def to_h
      %i[primitive_marker x y w h r g b a].map { |k| [k, send(k) ]}.to_h
    end
  end

  module Helpers
    def solid(**kwargs)
      Solid.new(**kwargs)
    end
    module_function :solid
  end
end
