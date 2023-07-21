

MAP_TILE_W = 10
MAP_TILE_H = 10

TILE_W = 64
TILE_H = 64


def grid_point(x,y)
  vec2(TILE_W*x, TILE_H*y)
end

def tile_source_rect(x, y, dims: grid_point(1,1))
  VP::Rect.new(position: grid_point(x,y), dimensions: dims )
end

CURRENT_CANVAS_OFFSET_FROM_WINDOW_ORIGIN = vec2(TILE_W, TILE_H)

class TerrainOptions
  include VP::Helpers
  include Layout::Helpers
  include UI::Helpers

  attr_reader :terrains, :display
  attr_accessor :selected_index

  def initialize(terrains, selected_tag = nil)
    @terrains = terrains
    select!(selected_tag) if selected_tag
  end

  # Input-handling
  def handle_click!(click)
    first_rect = terrain_swatches.first.layout_component.current_rect
    in_x = first_rect.x <= click.up.x &&
      (first_rect.x + first_rect.w) >= click.up.x

    last_rect = terrain_swatches.last.layout_component.current_rect
    in_y = first_rect.y <= click.up.y &&
      (last_rect.y + last_rect.h) >= click.up.y

    if in_y && in_x
      swatch_i = ((click.up.y - first_rect.y)/first_rect.h).to_i
      clicked_terrain = terrain_swatches[swatch_i]
      select!(swatch_i) if click.within?(clicked_terrain.layout_component.current_rect)
      return true
    end
    nil
  end
  # Done Input Handling

  def selected
    terrains[selected_index]
  end

  def terrain_by(name)
    terrains.find { |t| t.terrain_name == name }
  end

  def select!(index)
    return if @selected_index == index
    if index.is_a?(Symbol)
      @selected_index = terrains.find_index { |t| t.terrain_name == index }
    else
      @selected_index = index
    end
  end

  def layout_component
    Block.new.adopt!(banner, swatch_cursor).tap(&:place!)
  end

  def selected_terrain_swatch
    terrain_swatches[selected_index || 0]
  end

  def swatch_cursor
    selection_cursor(selected_terrain_swatch.layout_component.current_rect)
  end

  def banner
    return @banner if @banner
    terrains_column = Column.new(sizing: :wrap).adopt!(*(terrain_swatches.map(&:layout_component)))
    terrains_banner = UI::Banner.new(terrains_column).layout_children
    positioned_terrains_banner = Block.new(bounds: quick_bounds(64*10 + 30, 64), sizing: :wrap).adopt!(terrains_banner)
    positioned_terrains_banner.place!
    @banner = positioned_terrains_banner
  end

  def terrain_swatches
    @terrain_swatches ||= terrains.map do |terrain|
      TerrainSwatch.new(terrain)
    end
  end
end

class TerrainSwatch
  include Layout::Helpers
  attr_reader :terrain

  def initialize(terrain)
    @terrain = terrain
  end

  def layout_component
    @layout_component ||= Block.new(bounds: quick_bounds(0, 3, 56, 56)).
      adopt!(terrain.icon.sprite.clone)
  end
end

class TerrainOptionFactory
  attr_reader :all_terrains

  def initialize
    @all_terrains = [
      [:water, "Terrain/Water/Water2.png", vec2(0,0), :alone],
      [:terrace, "Terrain/Ground/Tilemap_Elevation2.png", vec2(0,4), :full],
      [:grass, "Terrain/Ground/Grass.png", vec2(0,0), :full],
      [:sand,  "Terrain/Ground/Sand.png", vec2(0,0), :full],
      [:cliff, "Terrain/Ground/Tilemap_Elevation2.png", vec2(0,3), :horizontal],
      [:stairs, "Terrain/Ground/Tilemap_Elevation2.png", vec2(0,0), :horizontal],
      [:bridge_vertical, "Terrain/Bridge/Bridge_All2.png", vec2(4,3), :vertical],
      [:bridge_horizontal, "Terrain/Bridge/Bridge_All2.png", vec2(0,3), :horizontal],
    ].map { |args| build_terrain(*args) }.
      insert(1, foam)
  end



  class LoopSprite < VP::Sprite
    def source_x
      # puts 3*TILE_W*(($gtk.args.state.tick_count >> 5) % 8) + TILE_W
      # puts "#{source_y} #{source_w} #{source_h}"
      (($gtk.args.state.tick_count >> 2) % 8)*3*TILE_W
    end
  end

  def foam
    sheet = Assets::Sheet.new(
      path: "assets/tiny_swords/Terrain/Water/Foam/Foam.png"
    ).assign!(pack_path: "")
    foam_sprite = LoopSprite.new(
      source: VP::Sprites::Source.new(
        bounds: quick_rect(0,0,sheet.dimensions.h, sheet.dimensions.h)),
        path: sheet.path)
    Assets::Terrain.new(
      { alone: Assets::Terrain.alone(foam_sprite) },
      terrain_name: :foam,
      convolve_by: [],
      offsets: { grid: vec2(0,0), bounds: vec2(-1, -1 ) }
    )
  end

  def build_line_8loop(path = "Terrain/Water/Foam/Foam.png", bounds_offset = vec2(-1, -1 ), terrain_name)
    sheet = Assets::Sheet.new(
      path: "assets/tiny_swords/#{path}"
    ).assign!(pack_path: "")
    foam_sprite = LoopSprite.new(
      source: VP::Sprites::Source.new(
        bounds: quick_rect(0,0,sheet.dimensions.h, sheet.dimensions.h)),
        path: sheet.path)
    Assets::Terrain.new(
      { alone: Assets::Terrain.alone(foam_sprite) },
      terrain_name: terrain_name,
      convolve_by: [],
      offsets: { grid: vec2(0,0), bounds: bounds_offset }
    )
  end

  def build_terrain(terrain_tag, path, start, terrain_type)
    sheet = Assets::Sheet.new(
      path: "assets/tiny_swords/#{path}"
    ).assign!(pack_path: "")
    sheet_grid = Grid.build(sheet.dimensions) do |i,j|
      VP::Sprite.new(
        path: sheet.path,
        source: VP::Sprites::Source.new(bounds: tile_source_rect(i, j)),
      )
    end
    Assets::Terrains.send("build_#{terrain_type}".to_sym, start, sheet_grid, terrain_tag)
  end
end