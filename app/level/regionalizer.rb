class Regionalizer
  attr_reader :terrain_layer, :rects, :todo_cells, :handled_grid

  def initialize(terrain_layer, start_at = VP::Helpers.quick_rect(2,2,1,1))
    @terrain_layer = terrain_layer
    @rects = [start_at]

    @handled_grid = Grid.build(terrain_layer.grid.dimensions - vec2(4,4), vec2(1,1))

    @handled_grid.assign_slice!(@handled_grid.visible_rect) do |i, j|
      cell = @terrain_layer[vec2(i,j)]
      {
        :handled? => !cell_walkable?(cell),
        :walkable? => cell_walkable?(cell)
      }
    end

    @todo_cells = []
  end

  def load_todos!
    @handled_grid.for_slice(@handled_grid.visible_rect) do |i,j, cell|
      @todo_cells << vec2(i,j).with_i if !cell[:handled?] && cell[:walkable?]
    end
    self
  end

  def print_grid
    puts "\n"
    puts (@handled_grid.visible_slice.rows.transpose.map do |row|
      row.map { |c| c[:walkable?] ? "x" : "_" }.join("")
    end).reverse.join("\n")
  end

  def process!
    while @todo_cells.count > 0
      grow_through_current_rect!
      @rects << VP::Helpers.rect(todo_cells.first, vec2(1,1))
      todo_cells.delete todo_cells.first
    end
  end

  def print_regions
    rects.each do |r|
      puts "\nregions:"
      puts r.to_h
    end
  end

  def grow_through_current_rect!
    grew = nil
    while grew.nil? || grew
      grew = grow_current!
    end
  end

  def current_rect
    rects.last.with_i.canonical
  end

  def current_rect=(r)
    @rect_updated_sentinel = true
    rects[rects.count - 1] = r.with_i
    @handled_grid.assign_slice!(current_rect) do |i, j, handled|
      @todo_cells.delete(vec2(i,j))
      handled[:handled?] = true
      handled
    end

    current_rect
  end


  def grow_current!
    @rect_updated_sentinel = false
    rx = VP::Helpers.quick_rect(current_rect.x - 1, current_rect.y, current_rect.w + 1, current_rect.h)
    rxs = VP::Helpers.quick_rect(current_rect.x - 1, current_rect.y, 1, current_rect.h)
    self.current_rect = rx.with_i if claimable_slice?(rxs)
    ry = VP::Helpers.quick_rect(current_rect.x, current_rect.y - 1, current_rect.w, current_rect.h + 1)
    rys = VP::Helpers.quick_rect(current_rect.x, current_rect.y - 1, current_rect.w, 1)
    self.current_rect = ry.with_i if claimable_slice?(rys)
    rw = VP::Helpers.quick_rect(current_rect.x, current_rect.y, current_rect.w + 1, current_rect.h)
    rws = VP::Helpers.quick_rect(current_rect.x + current_rect.w, current_rect.y,  1, current_rect.h)
    self.current_rect = rw.with_i if claimable_slice?(rws)
    rh = VP::Helpers.quick_rect(current_rect.x, current_rect.y, current_rect.w, current_rect.h + 1)
    rhs = VP::Helpers.quick_rect(current_rect.x, current_rect.y + current_rect.h , current_rect.w, 1)
    self.current_rect = rh.with_i if claimable_slice?(rhs)
    @rect_updated_sentinel
  end

  def claimable_slice?(rect)
    p1 = rect.canonical.p1
    p2 = rect.canonical.p2
    inbounds = p1.x > -1 && p1.y > -1 && p2.x < @handled_grid.dimensions.w && p2.y < @handled_grid.dimensions.h
    padded_rect = @handled_grid.pad(rect)
    valid_slice = (@handled_grid.slice(padded_rect).rows.flatten).all? do |c|
      !(c[:handled?]) && c[:walkable?]
    end
    inbounds && valid_slice
  end

  def cell_walkable?(cell)
    return false unless cell
    return true if (
      (cell[:grass] || cell[:terrace] || cell[:sand] || cell[:stairs]) &&
        !(cell[:cliff] &&  cell[:cliff].terrain_name == :cliff)
    ) || cell[:bridge_vertical]
    return false
  end
end