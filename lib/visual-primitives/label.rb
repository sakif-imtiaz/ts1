module VP
  module Helpers
    def text_label(size_enum: 1, font: "fonts/vinque/vinque.ttf", vertical_alignment_enum: 0, **kwargs)
      TextLabel.new(size_enum: size_enum, font: font, vertical_alignment_enum: vertical_alignment_enum, **kwargs)
    end
    module_function :text_label
  end

  class TextLabel
    include Arby::Attributes
    include Bounded
    include Colored
    include Util

    attr_accessor :text, :alignment_enum, :size_enum, :vertical_alignment_enum, :font, :blendmode_enum

    def initialize(**kwargs)
      assign!(**kwargs)
    end

    def primitive_marker
      :label
    end

    def w
      dimensions[0]
    end

    def h
      dimensions[1]
    end

    def current_rect
      VP::Rect.new(position: position, dimensions: vec2(w, h))
    end

    def dimensions
      @dimensions ||= $gtk.calcstringbox(text, size_enum, font)
    end

    def to_h
      %i(primitive_marker x y w h text).map {|sy| [sy,send(sy)] }.to_h
    end
  end
end
