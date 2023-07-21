

class Cell
  DEPTH = 10
  attr_reader :stack
  def initialize
    @stack = Array.new(10)
  end

  def to_json
    stack.filter_map.with_index do |cell_tile, i |
      if cell_tile
        ["#{i}", cell_tile.terrain_name]
      end
    end.to_h.to_json
  end

  def [](terrain_name)
    stack[order[terrain_name]]
  end

  def place(cell_tile)
    stack[order[cell_tile.terrain_name]] = cell_tile
  end

  def remove(terrain_name)
    stack[order[terrain_name]] = nil
  end

  def walkable?
    stack[2..6].compact.any? &&
      !(self[:cliff]&.terrain_name == :cliff && stack[6].nil?)
  end

  private

  def order
    self.class.order
  end

  def self.order
    @@_order ||= {
      water: 0,
      foam: 1,
      sea_rock: 1,
      terrace: 2,
      sand: 3,
      grass: 4,
      cliff: 5,
      stairs: 5,
      structure: 6,
      bridge_vertical: 6,
      bridge_horizontal: 6,
      items: 7,
      unit: 8,
      effects: 9
    }
  end
end

class TerrainLayerGrid
  attr_reader :terrain_options, :grid, :editable_dims

  def initialize(selected_terrain, editable_dims = vec2(MAP_TILE_W, MAP_TILE_H))
    @terrain_options = selected_terrain
    @editable_dims = editable_dims
    @grid = Grid.build(editable_dims + vec2(4,4)) do |_i, _j|
      Cell.new
    end
  end

  def [](vec)
    # return nil unless in_bounds?(vec)
    grid[(vec + vec2(2,2)).with_i]
  end

  def primitives
    (0...(Cell::DEPTH)).to_a.map do |depth|
      grid.
        rows.
        map(&:reverse).
        flatten.
        compact.
        map { |cell| cell.stack[depth] }.
        flatten.
        compact.
        map(&:sprite).
        filter(&:primitive_marker)
    end
  end

  def to_json
    rect = VP::Helpers.quick_rect(0,0, grid.rows.count - 4, grid.rows.first.count - 4).with_i
    grid.slice(nudge_rect(rect)).rows.to_json
  end

  def self.from_json(a_of_a)
    Grid.build(vec2(a_of_a.count, a_of_a.first.count)) do |i, j|
      Cell.from_json(a_of_a[i][j])
    end
  end

  def tile_source_rect(x, y, dims: grid_point(1,1))
    VP::Rect.new(position: grid_point(x,y), dimensions: dims)
  end

  def cells_rect
    @_cells_rect ||= VP::Helpers.quick_rect(0,0, MAP_TILE_W, MAP_TILE_W)
  end

  def in_bounds?(vec)
    tile_c = VP::Rect.new(position: vec, dimensions: vec2(1,1))
    if tile_c.inside_rect?(cells_rect.with_f)
      true
    else
      puts "OOB tile_c p1 #{tile_c.canonical.p1}"
      puts "OOB tile_c p2 #{tile_c.canonical.p2}"
      puts "OOB cells_rect #{cells_rect.with_f.to_h}"
      puts "#{tile_c.canonical.p1}.inside_rect?(#{cells_rect.to_h}) = #{tile_c.canonical.p1.inside_rect?(cells_rect)}"
      false
    end
  end

  def selected_terrain
    terrain_options.selected
  end

  def terrain_for(cell)
    # return nil unless cell && cell[selected_terrain.terrain_name].terrain_name

    sttn = selected_terrain.terrain_name
    tn = cell[sttn].terrain_name
    terrain_options.terrain_by tn
  end

  def []=(uo_vec, val)
    vec = uo_vec + selected_terrain.default.offsets.grid
    # raise "OOB" unless in_bounds?(vec)
    if val
      grid[(vec + vec2(2,2))].place(selected_terrain.default)
    else
      grid[(vec + vec2(2,2))].remove(selected_terrain.terrain_name)
    end

    ([vec + vec2(2,2)] + cross_coords(vec + vec2(2,2))).each do |co|
      next unless grid[co][selected_terrain.terrain_name]
      found_terrain = terrain_for(grid[co])
      terrain_key = cross_coords(co,found_terrain.convolve_by).zip(found_terrain.convolve_by).
        select do |(coco, cc)|
          grid[coco] && grid[coco][found_terrain.terrain_name] && grid[coco][found_terrain.terrain_name].terrain_name == found_terrain.terrain_name # && grid[coco][found_terrain.terrain_name].terrain_name == found_terrain.terrain_name
        end.
        map { |(_coco, cc)| cc }.
        sort_by { |cc| [cc.x, cc.y] }

      found_tile = found_terrain && found_terrain.sections[terrain_key]
      if found_tile
        grid[co].place found_tile.build_cell_tile(co)
      else
        grid[co][found_terrain.terrain_name] = nil
      end
    end
  end

  def cross(vec)
    cross_coords(vec).
      select { |v| grid[v] }
  end

  def cross_coords(vec, conv = full_convolve)
    conv.map { |off| (off + vec).with_i }.compact
  end

  def full_convolve
    self.class.full_convolve
  end

  def self.full_convolve
    @@_cross_offsets ||= [[-1, 0], [1, 0], [0, -1], [0, 1]].
      map do |(x,y)|
      vec2(x,y)
    end
  end

  def slice(rect)
    grid.slice(nudge_rect(rect))
  end

  def nudge_rect(rect)
    VP::Rect.new(position: (rect.position + vec2(2,2)), dimensions: rect.dimensions)
  end

  def paint!(rect)
    grid.for_slice(rect) do |i, j|
      self[vec2(i ,j).with_i] = true
    end
  end
end