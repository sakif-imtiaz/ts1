module Services
  class LayerSet
    attr_reader :layers
    def initialize
      @layers = [Layer.new(0)]
    end

    def <<(*elts)
      self[0].send(:<<, *elts)
    end

    def [](depth)
      ensure_layers!(depth)
      @layers[depth]
    end

    def ensure_layers!(depth)
      deepest = @layers.count - 1
      return if depth <= deepest
      additional_layers = ((deepest + 1)..depth).to_a.map do |i|
        Layer.new(i)
      end
      @layers.concat additional_layers
    end

    def reset!
      @layers.each(&:reset!)
    end

    def elements
      @layers.map { |layer| layer.elements  }
    end
  end

  class Layer
    attr_reader :elements, :depth

    def initialize(depth)
      @elements = []
      @depth = depth
    end

    def <<(*elts)
      elts.flatten.each { |elt| elt.layer = depth }
      @elements.concat elts
    end

    def reset!
      @elements.clear
    end
  end

  def primitives
    @@primitives ||= LayerSet.new
  end

  def static_primitives
    @@static_primitives ||= LayerSet.new
  end

  def primitive_buffer
    @@primitive_buffer ||= PrimitiveBuffer.new(primitives, static_primitives)
  end

  module_function :primitives
  module_function :static_primitives
  module_function :primitive_buffer

  class PrimitiveBuffer
    attr_reader :primitives, :static_primitives

    def initialize(primitives, static_primitives)
      @primitives, @static_primitives = primitives, static_primitives
    end

    def tick(args)
      args.outputs.primitives << primitives.elements
      args.outputs.static_primitives << static_primitives.elements
      primitives.reset!
      static_primitives.reset!
    end
  end
end


class GTK::Runtime
  # You can completely override how DR renders by defining this method
  # It is strongly recommend that you do not do this unless you know what you're doing.
  def primitives pass
    fn.each_send pass.solids,            self, :draw_solid
    fn.each_send pass.static_solids,     self, :draw_solid
    fn.each_send pass.sprites,           self, :draw_sprite
    fn.each_send pass.static_sprites,    self, :draw_sprite

    grouped_primitives = pass.primitives.group_by { |p| p.layer }
    grouped_static_primitives = pass.static_primitives.group_by { |p| p.layer }
    layer_keys = (grouped_primitives.keys + grouped_static_primitives.keys).uniq.sort
    layer_keys.each do |clayer|
      fn.each_send grouped_static_primitives[clayer] || [], self, :draw_primitive
      fn.each_send grouped_primitives[clayer] || [], self, :draw_primitive
    end

    fn.each_send pass.labels,            self, :draw_label
    fn.each_send pass.static_labels,     self, :draw_label
    fn.each_send pass.lines,             self, :draw_line
    fn.each_send pass.static_lines,      self, :draw_line
    fn.each_send pass.borders,           self, :draw_border
    fn.each_send pass.static_borders,    self, :draw_border

    if !self.production
      fn.each_send pass.debug,           self, :draw_primitive
      fn.each_send pass.static_debug,    self, :draw_primitive
    end

    fn.each_send pass.reserved,          self, :draw_primitive
    fn.each_send pass.static_reserved,   self, :draw_primitive
  end
end