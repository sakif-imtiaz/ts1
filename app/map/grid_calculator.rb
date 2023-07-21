class GridCalculator
    include VP::Helpers
    attr_reader :tile_size, :offset

    def initialize(tile_size, offset)
      @tile_size = tile_size.with_f
      @offset = offset
    end

    def grid_pt(unoffset_easel_pt)
      easel_pt = unoffset_easel_pt - offset
      vec2(
        (easel_pt.x*(1.0/tile_size.w)).floor,
        (easel_pt.y*(1.0/tile_size.h)).floor
      )
    end

    def on(easel_pt)
      VP::Rect.new(
        position: (grid_pt(easel_pt)).floor,
        dimensions: point(1, 1)
      )
    end

    def within(easel_rect)
      cer = easel_rect.canonical
      single = point(1, 1)
      gp1 = grid_pt(cer.position)
      gp2 = grid_pt(point(cer.x + cer.w, cer.y + cer.h))
      gd = gp2 - gp1
      VP::Rect.new(
        position: (gp1 + single),
        dimensions: (gd - single))
    end


    def touching(easel_rect)
      cer = easel_rect.canonical
      single = point(1, 1)
      gp1 = grid_pt(cer.position)
      gp2 = grid_pt(point(cer.x + cer.w, cer.y + cer.h))
      gd = gp2 - gp1
      VP::Rect.new(
        position: (gp1),
        dimensions: (gd + single))
    end
    #
    # def canonical(rect)
    #   c_x, c_x_w = [rect.x, rect.x + rect.w].sort
    #   c_y, c_y_h = [rect.y, rect.y + rect.h].sort
    #
    #   VP::Helpers.quick_rect(c_x, c_y, c_x_w - c_x, c_y_h - c_y)
    # end
  end