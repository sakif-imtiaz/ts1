class LayerOptions
  include VP::Helpers

  attr_reader :layers, :display
  attr_accessor :selected_layer_name

  # def self.build_terrain_options(*args, **kwargs)
  #   terrain_option_factory.build(*args, **kwargs)
  # end

  # def self.terrain_option_factory
  #   @@_terrain_option_factory ||= TerrainOptionFactory.new
  # end
  #
  # def self.build_with_custom_terrain_options
  #   water_layer = TerrainLayerGrid.new(build_terrain_options(:sand, :water, start: :water))
  #   water_layer.paint!(quick_rect(0,0,10,10))
  #   layers = {
  #     base: { name: :base, grid: water_layer},
  #     flat: { name: :flat, grid: TerrainLayerGrid.new(build_terrain_options(:grass, :bridge_vertical, :bridge_horizontal, start: :grass))},
  #     elevation: { name: :elevation, grid: TerrainLayerGrid.new(build_terrain_options(:terrace, :cliff, :stairs, start: :terrace)) }
  #   }
  #   new(layers, :base)
  # end

  def self.build_with_same_terrain_options(terrain_options)
    water_layer = TerrainLayerGrid.new(terrain_options)
    water_layer.paint!(quick_rect(3,2,6,7))
    layers = {
      base: { name: :base, grid: water_layer},
    }
    new(layers, :base)
  end

  def initialize(layers, selected_layer_name = nil)
    @layers = layers
    select!(selected_layer_name) if selected_layer_name
  end

  def selected_grid
    layers[selected_layer_name].grid
  end

  def check!(click_pt)
    found = display.map(&:first).find( -> {false}) do |layer_label|
      click_pt.inside_rect?(layer_label.current_rect.with_f.to_h)
    end
    return false unless found
    select!(found.text.to_sym)
  end

  def select!(layer_name)
    @selected_layer_name = layer_name
    @display = calculate_display
  end

  def layer_primitives
    layers.map { |k, l| l.grid.primitives }
  end

  def calculate_display
    position = vec2(640 + 64 + 300, 64).with_f
    layers.map.with_index do |(k, v), i|
      label = text_label(text: v.name.to_s, size_enum: -1, position: vec2(position.x, position.y + i*TILE_H + 10).with_f)
      border_bounds = quick_rect(label.x - 5, label.y - 5, label.w + 30, label.h + 30).with_f
      border = (k == selected_layer_name ? hollow_solid(bounds: border_bounds, color: color(:blue)) : nil)
      [label, border].compact
    end
  end
end

#
# module LayerControls
#   class LayerControl
#     def self.example(position = vec2(640 + 64 + 200, 264), rows = 2)
#       rows = [Row.new, Row.new]
#       new(position, rows)
#     end
#
#     attr_reader :layer_rows
#
#     def initialize(position, rows)
#       @layer_rows = rows
#
#     end
#
#
#   end
#
#   class Row
#     include VP::Helpers
#     attr_reader :bounds
#     def initialize
#       @bounds = quick_rect(0,0, 200, 100)
#     end
#   end
# end