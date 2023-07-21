
=begin
  TODO: Another possible mode: InheritSlice
    Similar to inherit. but the width/height isn't calculated off 100% of the parent.
    Instead, it's the parent dimensions minus the padding (which would be the offset + the opposite on the diagonal)
=end

class Div
  include VP::Helpers
  include Layout::Helpers
  include Arby::Attributes

  attr_reader :sizing
  attr_reader :bounds
  # attr_accessor :parent
  attr_reader :data
  attr_writer :current_rect
  attr_accessor :float
  attr_reader :rendering

  def initialize(
    bounds: quick_bounds,
    sizing: :inherit, float: false,
    static: false,
    data: {}
  )
    @bounds = bounds
    @sizing = sizing
    @float = float
    @children = [ { layout_children: [] } ]
    @data = data
    # @parent = nil
    @focused = false
    @active = false
    @rendering = Rendering.new(static ? STATIC : DYNAMIC)
  end

  def adopt!(*adopted, child_providers: [])
    adopt_children!(*adopted) if adopted.any?
    child_providers_ary = child_providers #Array.wrap(child_providers)
    adopt_child_providers!(*child_providers_ary) if child_providers_ary.any?
    self
  end

  def adopt_child_providers!(*child_providers)
    @children.concat(child_providers)
  end

  def adopt_children!(*adopted)
    # adopted.flatten.
    #   select { |child| child.primitive_marker.nil? }.
    #   each { |child| child.parent = self }
    ac = { layout_children: adopted }
    @children.concat([ac])
  end

  def current_rect
    @current_rect ||= quick_rect(0,0,0,0)
  end

  def base_rect
    if sizing == :wrap || float
      quick_rect(0,0,0,0)
    else
      window_rect
    end
  end

  def resolved_wrap_rect(provided_rect = base_rect)
    rect(resolved_offset(provided_rect), resolved_dimensions(provided_rect))
  end

  def resolved_offset(provided_rect = base_rect)
    vec2(
      bounds.x.against(provided_rect.w),
      bounds.y.against(provided_rect.h)
    )
  end

  def resolved_position(provided_rect = window_rect)
    resolved_offset(provided_rect) + provided_rect.position
  end

  def resolved_dimensions(parent_rect = base_rect)
    if sizing == :wrap
      rd_h = resolved_dims_wrap(parent_rect)
      vec2(rd_h.w, rd_h.h)
    else
      rd_h = resolved_dims_inherit(parent_rect)
      vec2(rd_h.w, rd_h.h)
    end
  end

  def resolved_dims_wrap(provided_dims)
    cwr = wrap_dims
    { w: bounds.w.against(cwr.w || provided_dims.w),
      h: bounds.h.against(cwr.h || provided_dims.h) }
  end

  def resolved_dims_inherit(provided_dims)
    { w: bounds.w.against(provided_dims.w),
      h: bounds.h.against(provided_dims.h) }
  end

  def size_label
    # unless data.hide_label || (children.first.primitive_marker == :sprite && children.first.path == "assets/tiny_swords/UI/Banners/Banner_Vertical.png")
    #   label_position = current_rect.position.clone
    #   label_position.y += current_rect.h - 15 if data.label_position == :top_right
    #   [
    #     text_label(size_enum: -2, position: label_position, font: nil,
    #                text: "#{(current_rect.dimensions.w).to_i}, #{(current_rect.dimensions.h).to_i}")
    #   ]
    # else
      []
    # end
  end

  def primitive_marker
    nil
  end

  def children
    @children.map(&:layout_children).flatten
  end

  def renderables
    (children + size_label).map do |child|
      if child.primitive_marker
        child
      else
        child.renderables
      end
    end
  end

  def flow_children
    children.select { |child| !child.primitive_marker && !child.float }
  end

  def float_children
    children.select { |child| child.primitive_marker || child.float }
  end

  def render(parent_resolved_mode = DYNAMIC, parent_resolved_layer = 0, root: false)
    rendering.render(self, parent_resolved_mode, parent_resolved_layer, root: root)
  end
end

class Arranged < Div
  def place!(provided_rect)
    rp = resolved_position(provided_rect)
    rd = wrap_dims

    by = rp - current_rect.position

    children.each { |p| p.bounds.nudge!(by) }
    @current_rect = rect(rp, rd)
  end

  def resolved_dimensions(_rect)
    wrap_dims
  end

  def wrap_dims
    @_wrap_dims ||= children.
      map { |child| child.bounds }.
      reduce(quick_rect(0, 0, 0.0, 0.0), :merge).
      canonical.p2
  end
end

class Block < Div
  def place!(provided_rect = base_rect)
    rp = resolved_position(provided_rect)
    rd = resolved_dimensions(provided_rect)

    # next_current_rect = rect(rp, rd)
    # if next_current_rect == @current_rect
    #   puts "skipping #{data.name}" if data.name
    #   return @current_rect
    # end
    @current_rect = rect(rp, rd)

    flow_children.each do |child|
      child.place!(@current_rect.clone)
    end

    float_children.each do |child|
      child.place!(@current_rect)
    end
    @current_rect
  end

  def place_children!
    flow_children.each do |child|
      child.place!(@current_rect.clone)
    end

    float_children.each do |child|
      child.place!(@current_rect)
    end
  end

  def wrap_dims
    flow_children.
      map { |child| child.resolved_wrap_rect }.
      reduce(quick_rect(0, 0, 0.0, 0.0), :merge).
      canonical.p2
  end
end

class Serial < Div
  def place!(provided_rect = base_rect)
    rp = resolved_position(provided_rect)
    rd = resolved_dimensions(provided_rect)

    @current_rect = rect(rp, rd)
    serial_element_offset = @current_rect.clone
    flow_children.each do |child|
      # row_element_rect = child.place!(row_element_offset.clone)
      # row_element_offset.x += row_element_rect.w
      serial_element_rect = child.place!(serial_element_offset.clone)
      serial_offset!(serial_element_rect, serial_element_offset)
    end

    float_children.each do |child|
      child.place!(@current_rect)
    end
    @current_rect
  end

  def wrap_dims
    flow_children.
      map { |child| child.resolved_wrap_rect }.
      reduce(quick_rect(0, 0, 0.0, 0.0)) do |memo, offset_rect|
      serial_offset!(offset_rect, memo) # offset_rect.x += memo.w
      memo.merge(offset_rect)
    end.canonical.p2
  end
end

class Row < Serial
  def serial_offset!(serial_element_rect, serial_element_offset)
    serial_element_offset.x += serial_element_rect.w + serial_element_rect.x - serial_element_offset.x
  end
end

class Column < Serial
  def serial_offset!(serial_element_rect, serial_element_offset)
    serial_element_offset.y += serial_element_rect.h + serial_element_rect.y - serial_element_offset.y
  end
end

DYNAMIC = 0
STATIC  = 1

class Rendering
  attr_reader :mode
  attr_reader :cached_rect
  attr_accessor :layer
  def initialize(mode = nil, layer = 0)
    @rendered = false
    @mode = mode
    @layer = layer
  end

  def rendered?
    @rendered
  end

  def render(component, parent_mode = DYNAMIC, parent_resolved_layer = 0, root: false)
    resolved_mode = mode || parent_mode
    should_render = should_render?(resolved_mode)
    component.place! if root # component.parent.nil?
    resolved_layer = layer || parent_resolved_layer
    # if component.data.name == "selected unit icons"
    #   # puts "rendering selected unit icons"
    #   puts "children.count: #{component.children.second.children.first.children.first.children.first.children.first.to_h}"
    # end
    component.children.each do |child|
      if should_render
        if child.primitive_marker
          if static?
            Services.static_primitives[resolved_layer] << child
          else
            Services.primitives[resolved_layer] << child
          end
        else
          child.render(resolved_mode, resolved_layer)
        end
      end
    end
    @rendered = true if resolved_mode == STATIC
  end

  def static?
    @mode == STATIC
  end

  def should_render?(resolved_mode)
    resolved_mode == DYNAMIC ||
      resolved_mode == STATIC && !rendered?
  end
end


module Clickable
  include Pushy::Helpers

  def click›
    @click› ||= Services.mouse.clicks›.chain(
      # with_latest_from(layout_component.current_rect),
      filter { |click| click.within?(layout_component.current_rect) },
    )
  end

  def on_clickß(&blk)
    @on_clickß ||= click›.subscribe do |click|
      blk.call(click)
    end
  end
end
