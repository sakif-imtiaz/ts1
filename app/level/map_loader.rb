class MapLoader
  attr_reader :terrain_layer, :grid_dims
  attr_reader :parsed, :sublayer_i
  def initialize(path, terrain_layer = nil, terrain_options = nil, tof = nil)
    @parsed = $gtk.parse_json_file(path)["grid"]
    @grid_dims = vec2(parsed.count, parsed.first.count)
    @_tof = tof
    @_terrain_options = terrain_options
    @_terrain_layer = terrain_layer
    @sublayer_i = 0
  end

  def load_next_sublayer!
    parsed.each.with_index do |rows, i|
      rows.each.with_index do |cell_h, j|
        if terrain_name = cell_h["#{sublayer_i}"].try(:to_sym)
          terrain_options.select!(terrain_name)
          terrain_layer[vec2(i,j)]= true
        end
      end
    end
    @sublayer_i += 1
  end

  def loading?
    Cell::DEPTH >= @sublayer_i
  end

  def terrain_layer
    @_terrain_layer ||= TerrainLayerGrid.new(self.terrain_options, grid_dims)
  end

  def terrain_options
    @_terrain_options ||= TerrainOptions.new(tof.all_terrains, :water)
  end

  def tof
    @_tof ||= TerrainOptionFactory.new
  end
end