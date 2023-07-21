
# require "./lib/pushy/pushy.rb"

require "./spec/layout/lengths.rb"

=begin
 TODO: Ideas
  - TerminalComponent < Component
    - to handle primitives
  - Volatility & ChangeChecking
    - Observable#volatile = true
    - NullObservable(maybe unneccessary)
      - #volatile = true
      - #subscribe, currentValue, maybe some other stuff

=end


module Components
  module Layouts
    module Placements
      class Onto
        def self.resolve_child_positions!(component)
          component.offsettable_children.each do |child|
            child.rect.position = child.calculate_local_position(component) + component.rect.position
          end
        end

        def self.wrap_dimensions(component)
          component.flow_children.map(&:rect).reduce(:merge).dimensions
        end
      end

      class Horizontal
        def self.resolve_child_positions!(component)
          serial_element_offset = component.rect.position
          component.offsettable_children.each do |child|
            child.rect.position = child.calculate_local_position(component) + serial_element_offset
            serial_element_offset = serial_element_offset + component.rect.w
          end
        end

        def self.wrap_dimensions(component)
          dims = component.flow_children.map(&:rect).reduce(:merge).dimensions
          dims.w = component.flow_children.map(&:rect).map(&:w).reduce(&:+)
          dims
        end
      end
    end

    class Layout
      include Arby::Attributes
      include VP::Helpers

      attr_accessor :size, :offset, :float, :sizing, :placement

      def initialize(**kwargs)
        assign!(**kwargs)
      end

      def self.param_keys
        %i(size offset float sizing placement)
      end
      #
      # def resolve_position(_component, parent)
      #   against_rect = parent ? parent.rect : window_rect
      #   offset.against(against_rect.position)
      # end

      def calculate_local_position(_component, parent)
        against_rect = parent ? parent.rect : window_rect
        offset.against(against_rect.position)
      end

      def resolve_child_positions!(component)
        placement.resolve_child_positions!(component)
      end

      # def resolve_size!(component, parent)
      #   if size.padding?
      #     @resolved_size = size.pad(parent.layout.resolved_size)
      #   end
      # end

      def resolved_size
        @resolved_size ||= size
      end

      def calculate_dimensions(component, parent)
        against_rect = case sizing
                       when :inherit
                         parent ? parent.rect.dimensions : window_rect
                       when :wrap
                         placement.wrap_dimensions(component)
                       when :explicit
                         zero_rect # assumes the "resolved_size" is explicit
                       end

        resolved_size.against(against_rect)
      end
    end
  end

  class Component
    include VP::Helpers

    attr_reader :layout
    attr_reader :rendering
    attr_reader :rect
    attr_reader :data

    def self.param_keys
      %i(layout rendering)
    end

    def initialize(**kwargs)
      @layout = kwargs[:layout]
      @rendering = kwargs[:rendering] || Rendering.new()
      data_kwargs = kwargs.reject {|k,_v| Component.param_keys.include?(k) }
      @data = data_kwargs.to_h
      @children = []
      @rect = zero_rect
    end

    def around!(*children)
      @children.concat children
      self
    end

    def name
      data[:name]
    end

    def wrap?
      layout.sizing == :wrap
    end

    def float?
      layout.float
    end

    def resolve_dimensions!(parent)
      rect.dimensions = layout.calculate_dimensions(self, parent)
    end

    def resolve_child_positions!
      layout.resolve_child_positions!(self)
    end

    def calculate_local_position(parent)
      layout.calculate_local_position(self, parent)
    end

    def render_root
      # bottom_up { |component, parent| component.layout.resolve_size!(component, parent) }
      bottom_up { |component, parent| component.resolve_dimensions!(parent) if component.wrap? }
      top_down { |component, parent| component.resolve_dimensions!(parent) unless component.wrap? }
      top_down do |component, _parent|
        component.resolve_child_positions!
        # component.sized
      end
      top_down do |component, _parent|
        component.primitive_children.place!(component.rect)
      end
      component.render(parent)
      # top_down { |component, parent| component.resolve_position!(parent) }
    end

    def leaf?
      component_children.none?
    end

    def top_down(parent = nil, &block)
      if leaf?
        block.call(self, parent)
      else
        block.call(self, parent)
        component_children.each do |component_child|
          component_child.top_down(self, &block)
        end
      end
    end

    def bottom_up(parent = nil, &block)
      if leaf?
        block.call(self, parent)
      else
        component_children.each do |component_child|
          component_child.bottom_up(self, &block)
        end
        block.call(self, parent)
      end
    end

    def children
      @children
    end

    def component_children
      children.reject(&:primitive_marker)
    end

    def primitive_children
      children.select(&:primitive_marker)
    end

    def float_children
      component_children.reject(&:float?)
    end

    def offsettable_children
      float_children
    end

    def primitive_marker
      nil
    end

    def render(parent, resolved_mode)
      rendering.render(self, parent, resolved_mode)
    end
  end

  module Rendering
    DYNAMIC = 0
    STATIC  = 1

    class Config
      attr_reader :mode
      attr_accessor :layer
      def initialize(mode = nil, layer = 0)
        @rendered = false
        @mode = mode
        @layer = layer
      end
    end

    def render(component, parent, resolved_mode)
      resolved_mode = mode || resolved_mode
      should_render = should_render?(resolved_mode)
      buffer = buffer(resolved_mode)

      if should_render
        component.children.each do |child|
          if child.primitive_marker
            buffer << child
          else
            child.render(parent, resolved_mode)
          end
        end
      else
        component.children.each do |child|
          child.render(parent, resolved_mode)
        end
      end
    end

    def buffer(resolved_mode)
      resolved_mode == STATIC ? Services.static_primitives[layer] : Services.primitives[layer]
    end

    def static?
      @mode == STATIC
    end

    # def should_render?(resolved_mode, provided_rect)
    #   ((resolved_mode == DYNAMIC) || (cached_rect != provided_rect)) ||
    #     (resolved_mode == STATIC && !rendered?)
    # end

    def should_render?(resolved_mode)
      (resolved_mode == DYNAMIC) ||
        (resolved_mode == STATIC && !rendered?)
    end
  end

  # class Explicit
  #   def against(whatever)
  #     #hmm
  #     whatever
  #   end
  # end

  module Helpers
    # def self.explicit
    #   @@_passthrough ||= (Struct.new do
    #     def against(whatever)
    #       whatever
    #     end
    #   end).new
    # end
    # module_function :explicit

    def layout(**kwargs)
      Layouts::Layout.new(**kwargs)
    end
    module_function :layout

    def parent(*args, **kwargs)
      the_layout = kwargs[:layout] || layout(sizing: :inherit, placement: placements.onto)
      the_layout.wrap = false
      Component.new(*args, layout: the_layout, **(kwargs.reject { |k,_v| k == :layout} ))
    end
    module_function :parent

    def wrapper(*args, **kwargs)
      the_layout = kwargs[:layout] || layout(sizing: :wrap, placement: placements.onto)
      the_layout.wrap = true
      Component.new(*args, layout: the_layout, **(kwargs.reject { |k,_v| k == :layout} ))
    end

    module_function :wrapper

    def self.placements
      @@_placements ||= {
        onto: Layouts::Placements::Onto,
        row: Layouts::Placements::Row,
      }
    end

    module_function :placements
  end

end