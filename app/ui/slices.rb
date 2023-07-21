module UI
  UI_W = 64
  UI_H = UI_W

  class Banner
    extend ::Layout::Helpers
    def self.example_single
      new(
        Block.new(bounds: quick_rect(w: 64, h: 64)).
          adopt!(solid(color: :red))
      )
    end

    def self.example

      rows = %i(purple_heart
purple_html_css
purple_mountain_majesty
purple_munsell
purple_pizzazz
purple_taupe
purple_x11
quartz
rackley
radical_red
rajah
raspberry
raspberry_glace
raspberry_pink
raw_umber).each_slice(3).map do |cs|
        swatches = cs.map do |c|
          swatch(c)
        end
        Row.new(sizing: :wrap).adopt!(*swatches, Block.new(bounds: quick_rect(w: 15, h: 0)))
      end

      # Column.new(bounds: quick_rect(w: 256, h:256)).adopt!(

      new(Column.new(sizing: :wrap).adopt!(*rows))
    end

    def self.swatch(color_name)
      Block.new(bounds: quick_rect(4,4, 56, 56)).adopt!(
        solid(color: color_name),
        hollow_solid(color: color(color_name).darken(0.7))
      )
    end

    attr_reader :contained

    include Layout::Helpers
    include VP::Helpers

    def initialize(contained)
      @contained = contained
    end

    def layout_children
      @_layout_children ||= recalculate!
    end

    def recalculate!
      cco_x, cco_y = centered_contained_offset.x, centered_contained_offset.y
      @_layout_children = Block.new(bounds: offset(clip), sizing: :wrap, data: { name: "selected unit icons" }).adopt!(
        tiles,
        Block.new(bounds: offset(cco_x, cco_y), sizing: :wrap).adopt!(contained)
      )
    end

    # def tiles
    #   Arranged.wrap([corners, edges, center].flatten)
    # end

    def tiles
      Arranged.new.adopt!([corners, edges, center].flatten)
    end

    def center_dims
      center_grid_dims*UI_W
    end

    def center_grid_dims
      (contained.resolved_dimensions.with_f * (1/(UI_W))).ceil.with_i
    end

    def centered_contained_offset
      (center_dims - contained.resolved_dimensions)*0.5 + vec2(UI_W, UI_H)*(1 + 0.5*tpad)
    end

    def tpad
      # number of tiles to pad by
      0
    end

    def tile_source(gx, gy)
      VP::Sprites::Source.new(bounds: quick_rect(gx*UI_W, gy*UI_H, UI_W, UI_H))
    end

    def clip
      vec2(-36,-30)
    end

    def center
      iw = center_grid_dims.w+tpad
      ih = center_grid_dims.h+tpad
      (1..iw).to_a.flat_map do |i|
        (1..ih).to_a.map do |j|
          sprite(
            source: tile_source(1, 1),
            path: path,
            bounds: quick_rect(UI_W*i, UI_H*j, UI_W, UI_H)
          )
        end
      end
    end

    def corners
      iw = center_grid_dims.w + tpad
      ih = center_grid_dims.h + tpad
      [[0,0,0,0], [0,2,0,ih+1], [2, 0, iw+1, 0], [2,2, iw+1, ih+1]].
        map do |(gs_x, gs_y, g_x, g_y)|
          sprite(
            source: tile_source(gs_x, gs_y),
            path: path,
            bounds: quick_rect(g_x * UI_W, g_y*UI_W, UI_W, UI_H)
          )
      end
    end

    def edges
      iw = center_grid_dims.w + tpad
      ih = center_grid_dims.h + tpad

      bottom = (1..iw).to_a.map do |bottom_i|
        sprite(
          source: tile_source(1, 0),
          path: path,
          bounds: quick_rect(UI_W*bottom_i, 0, UI_W, UI_H)
        )
      end

      top = (1..iw).to_a.map do |top_i|
        sprite(
          source: tile_source(1, 2),
          path: path,
          bounds: quick_rect(UI_W*top_i, UI_H*(ih + 1), UI_W, UI_H)
        )
      end

      left = (1..ih).to_a.map do |left_i|
        sprite(
          source: tile_source(0, 1),
          path: path,
          bounds: quick_rect(0, UI_H*left_i, UI_W, UI_H),
        )
      end


      right = (1..ih).to_a.map do |right_i|
        sprite(
          source: tile_source(2, 1),
          path: path,
          bounds: quick_rect(UI_W*(iw + 1), UI_H*right_i, UI_W, UI_H)
        )
      end

      [bottom, top, left, right].flatten
    end

    def path
      "assets/tiny_swords/UI/Banners/Banner_Vertical.png"
    end
  end
end
