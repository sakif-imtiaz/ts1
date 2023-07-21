module Assets
  class TerrainTile
    attr_reader :terrain_name, :sprite, :offsets
    def initialize(sprite, terrain_name, offsets: {grid: vec2(0,0), bounds: vec2(0,0)})
      @sprite, @terrain_name, @offsets = sprite, terrain_name, offsets
    end

    def build_cell_tile(at_grid)
      offset_at_grid = at_grid + offsets.bounds
      CellTile.new(
        self.sprite.class.new(
          bounds: tile_source_rect(offset_at_grid.x - 2, offset_at_grid.y - 2, dims: self.sprite.source.dimensions),
          path: self.sprite.path,
          source: self.sprite.source.clone
        ),
        terrain_name
      )
    end
  end

  class CellTile
    attr_reader :terrain_name, :sprite
    def initialize(sprite, terrain_name)
      @sprite, @terrain_name, = sprite, terrain_name
    end
  end

  module Terrains
    def build_full(start, sheet, terrain_tag)
      sections = {
        vertical: Assets::Terrain.vertical(
          *sheet.slice(vp_rect(start + vec2(3,1), vec2(1,3))).rows.flatten),
        horizontal: Assets::Terrain.horizontal(
          *sheet.slice(vp_rect(start,  vec2(3,1))).rows.flatten),
        alone: Assets::Terrain.alone(sheet[start + vec2(3,0)]),
        blob: Assets::Terrain.blob(
          sheet.slice(vp_rect(start + vec2(0,1), vec2(3,3))))
      }
      convolve_by = [[-1, 0], [1, 0], [0, -1], [0, 1]].map { |(x,y)| vec2(x,y) }
      Assets::Terrain.new(sections, terrain_name: terrain_tag, convolve_by: convolve_by)
    end
    module_function :build_full

    def build_vertical(start, sheet, terrain_tag)
      sections = {
        vertical: Assets::Terrain.vertical(
          *sheet.slice(vp_rect(start + vec2(0,1), vec2(1,3))).rows.flatten),
        alone: Assets::Terrain.alone(sheet[start]),
      }
      convolve_by = [[0, -1], [0, 1]].map { |(x,y)| vec2(x,y) }
      Assets::Terrain.new(sections, terrain_name: terrain_tag, convolve_by: convolve_by)
    end
    module_function :build_vertical

    def build_horizontal(start, sheet, terrain_tag)
      sections = {
        horizontal: Assets::Terrain.horizontal(
          *sheet.slice(vp_rect(start,  vec2(3,1))).rows.flatten),
        alone: Assets::Terrain.alone(sheet[start + vec2(3,0)]),
      }
      convolve_by = [[-1, 0], [1, 0]].map { |(x,y)| vec2(x,y) }
      Assets::Terrain.new(sections, terrain_name: terrain_tag, convolve_by: convolve_by)
    end

    module_function :build_horizontal

    def build_alone(start, sheet, terrain_tag)
      sections = { alone: Assets::Terrain.alone(sheet[start]) }
      convolve_by = []#[vec2(0,0)]
      Assets::Terrain.new(sections, terrain_name: terrain_tag, convolve_by: convolve_by)
    end

    module_function :build_alone
  end

  class Terrain
    attr_reader :sections, :icon, :terrain_name, :convolve_by

    def to_h
      sections
    end

    def default
      sections[ [] ]
    end

    def initialize(sections, terrain_name:, convolve_by:, offsets: {grid: vec2(0,0), bounds: vec2(0,0)})
      @convolve_by = convolve_by
      merged_sections = sections.values.inject{|tot, new| tot.merge(new)} || {}
      @sections = merged_sections.map do |(k, v)|
        nk = k.nil? ? [] : k
        tagged_v = TerrainTile.new(v, terrain_name, offsets: offsets) # v.tap { |nv| nv.data.terrain_tag = terrain_name }
        [nk.sort_by { |q| [q.x, q.y] }, tagged_v]
      end.to_h
      @icon = @sections[ [] ]
      @terrain_name = terrain_name
    end

    def self.vertical(bottom, middle, top)
      [[vec2(0, -1)], [vec2(0, -1), vec2(0, 1)], [vec2(0,1)]].
        zip([top, middle, bottom]).to_h
    end

    def self.horizontal(left, middle, right)
      [[vec2(-1, 0)], [vec2(-1, 0), vec2(1,0)], [vec2(1,0)]].
        zip([right, middle, left]).to_h
    end

    def self.alone(alone)
      {[] => alone}
    end

    def self.blob(slice)
      blob_presences = [
        [vec2(1, 0), vec2(0, 1)], [vec2(-1, 0), vec2(1, 0), vec2(0, 1)], [vec2(-1, 0), vec2(0, 1)],
        [vec2(1, 0), vec2(0, 1), vec2(0, -1)], [vec2(-1, 0), vec2(1, 0), vec2(0, 1), vec2(0, -1)], [vec2(-1, 0), vec2(0, 1), vec2(0, -1)],
        [vec2(1, 0), vec2(0, -1)], [vec2(-1, 0), vec2(1, 0), vec2(0, -1)], [vec2(-1, 0), vec2(0, -1)]
      ].map do |presences|
        presences.sort_by { |v| [v.x, v.y] }
      end
      # blob_presences.each do |row|
      #   puts row.join("         ")
      # end
      nine_slice_dirs.zip(
        blob_presences
      ).map do |(grid_location, presences)|
        [presences, slice[grid_location]]
      end.to_h
    end

    def self.nine_slice_dirs
      @@_dir_to_check ||= [ vec2(0,0), vec2(1,0), vec2(2,0),
                            vec2(0,1), vec2(1,1), vec2(2,1),
                            vec2(0,2), vec2(1,2), vec2(2,2)
      ]
    end
  end
end