class InversionApp
  include VP::Helpers
  include Layout::Helpers

  def perform_tick(args)
    # if args.state.tick_count == 1
      args.outputs.primitives << review.renderables
    # end
  end

  def review
    # return @review if @review

    @review =
      component(
        column(
          build_swatch(:cornflower_blue),
          build_swatch(:carnation_pink)
        ),
        component(
          hollow_solid(color: :black),
          bounds: quick_bounds(x:'-20px', y:'-20px', w: '100% 40px', h: '100% 40px')
        )
      )

    @review.place!(parent_rect: quick_rect(300,300,200,200))
    @review
    # @review
  end

  def ideal
    swatches = row(build_swatch(:cornflower_blue), build_swatch(:carnation_pink))
    wrap(swatches).with(

      padding: quick_padding(10, 10, 10, 10)
    )
  end

  def build_swatch(color)
    component(
      solid(color: color),
      hollow_solid(color: color(color).darken(0.5)),
      bounds: quick_bounds(w: '80px', h: '60px'))
  end
end

class Div
  include Arby::Attributes

  attr_reader :display_mode, :explicit_rect
  attr_reader :children

  def initialize(explicit_rect, display_mode = :block, parent = nil)
    @explicit_rect, @display_mode = explicit_rect, display_mode
    @parent = parent
    @children = []
  end

  def resolved_rect
    @resolved_rect ||= resolve_rect!
  end

  def resolve_rect!
    @resolved_rect = %i(x y w h).map do |p|
      pv = x || resolve(p)
      [p, pv]
    end.to_h
  end

  def resolve(sym)
    if display_mode == :block
      parent.resolved_rect.send(sym)
    end
  end

  # def place!
  #   children.map do |child|
  #     if child.primitive_marker?
  #       child
  #     else
  #       child.renderables.place!(resolved_rect)
  #     end
  #   end
  # end

  def renderables
    children.map do |child|
      if child.primitive_marker?
        child
      else
        child.renderables
      end
    end
  end

  def primitive_marker
    nil
  end
end



module UI
  class Banner
    attr_reader :contained

    include VP::Helpers
    def self.example
      new(solid(color: color(:red), bounds: rect(vec2(0,0), vec2(200, 200))))
    end

    def initialize(contained, rect_provider = ContentPosition)
      @contained = contained
      extend rect_provider
    end

    def internal_grid_dimensions
      (contained.bounds.dimensions.with_f * (1/(UI_W))).ceil
    end

    def dimensions
      vec2(internal_grid_dimensions.x + 3, internal_grid_dimensions.y + 3) * UI_W
    end

    def bounds
      rect(contained.bounds.position - vec2(UI_W, UI_H)*1.5 - (internal_grid_dimensions*UI_W - contained.bounds.dimensions)*0.5, dimensions)
    end

    def renderables
      [
        corners,
        edges,
        center
      ]
    end

    def center
      iw = internal_grid_dimensions.w
      ih = internal_grid_dimensions.h
      (1..(iw + 1)).to_a.flat_map do |i|
        (1..(ih + 1)).to_a.map do |j|
          sprite(
            bounds: quick_rect(UI_W*i, UI_H*j, UI_W, UI_H),
            source: VP::Sprites::Source.new(bounds: quick_rect(UI_W, UI_H, UI_W, UI_H)),
            path: path
          )
        end
      end
    end

    def corners
      iw = internal_grid_dimensions.w
      ih = internal_grid_dimensions.h
      [[0,0,0,0], [0,2,0,ih + 2], [2, 0, iw + 2, 0], [2,2, ih + 2, iw + 2]].
        map do |(gs_x, gs_y, g_x, g_y)|
        sprite(
          bounds: quick_rect(g_x * UI_W, g_y*UI_W, UI_W, UI_H),
          source: VP::Sprites::Source.new(bounds: quick_rect(gs_x * UI_W, gs_y*UI_W, UI_W, UI_H)),
          path: path
        )
      end
    end

    def edges
      iw = internal_grid_dimensions.w
      ih = internal_grid_dimensions.h

      bottom = (1..(iw + 1)).to_a.map do |bottom_i|
        sprite(
          bounds: quick_rect(UI_W*bottom_i, 0, UI_W, UI_H),
          source: VP::Sprites::Source.new(bounds: quick_rect(UI_W, 0, UI_W, UI_H)),
          path: path
        )
      end

      top = (1..(iw + 1)).to_a.map do |top_i|
        sprite(
          bounds: quick_rect(UI_W*top_i, UI_H*(ih + 2), UI_W, UI_H),
          source: VP::Sprites::Source.new(bounds: quick_rect(UI_W, 2*UI_H, UI_W, UI_H)),
          path: path
        )
      end

      left = (1..(ih + 1)).to_a.map do |left_i|
        sprite(
          bounds: quick_rect(0, UI_H*left_i, UI_W, UI_H),
          source: VP::Sprites::Source.new(bounds: quick_rect(0, UI_H, UI_W, UI_H)),
          path: path
        )
      end


      right = (1..(ih + 1)).to_a.map do |right_i|
        sprite(
          bounds: quick_rect(UI_W*(iw + 2), UI_H*right_i, UI_W, UI_H),
          source: VP::Sprites::Source.new(bounds: quick_rect(2*UI_W, UI_H, UI_W, UI_H)),
          path: path
        )
      end

      [bottom, top, left, right].flatten
      # []
    end

    def path
      "assets/tiny_swords/UI/Banners/Banner_Vertical.png"
    end
  end
end

