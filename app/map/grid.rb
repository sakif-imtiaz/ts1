class Grid
  attr_accessor :dimensions, :rows, :padding

  def self.build(dimensions, padding = vec2(0,0))
    n = new
    n.padding = padding
    n.dimensions = dimensions.with_i
    n.reset_grid!
    if block_given?
      n.assign_slice!(n.visible_rect) do |i, j|
        yield i, j
      end
    end

    n
  end

  def map
    rows.map.with_index do |row, i|
      row.map.with_index do |cell, j|
        yield cell, i, j
      end
    end
  end

  def self.from_rows(rows)
    new.tap do |n|
      n.dimensions = vec2(rows.size, rows.first.size).with_i
      n.rows = rows
    end
  end

  def reset_grid!
    @rows = Array.new(dimensions.w + padding.w*2) do |_i|
        Array.new(dimensions.h + padding.h*2)
    end
  end

  def [](vec)
    ivec = (vec + padding).with_i
    raise "invalid coordinates #{ivec.to_h}" unless rows[ivec.x]
    rows[ivec.x][ivec.y]
  end

  def []=(vec, other)
    set!(vec, other)
  end

  def set!(vec, other)
    ivec = (vec + padding).with_i
    rows[ivec.x][ivec.y] = other
  end

  def slice(rect)
    cirect = rect.with_i.canonical
    p1 = cirect.p1
    p2 = cirect.p2
    self.class.from_rows(@rows[(p1.x)...(p2.x)].map do |slice_row|
      slice_row[(p1.y)...(p2.y)]
    end)
  end

  def for_slice(rect)
    cirect = rect.with_i.canonical
    p1 = cirect.p1.with_i
    p2 = cirect.p2.with_i
    ((p1.x)...(p2.x)).to_a.each do |i|
      ((p1.y)...(p2.y)).to_a.each do |j|
          yield i, j, self[vec2(i,j)]
      end
    end
  end

  def pad(rect)
    VP::Helpers.rect(padding + rect.position, rect.dimensions)
  end

  def visible_rect
    VP::Helpers.rect(vec2(0,0), dimensions)
  end

  def visible_slice
    self.slice(pad(visible_rect))
  end

  def assign_slice!(rect)
    cirect = rect.with_i.canonical
    p1 = cirect.p1.with_i
    p2 = cirect.p2.with_i
    ((p1.x)...(p2.x)).to_a.each do |i|
      ((p1.y)...(p2.y)).to_a.each do |j|
        self[vec2(i,j)] = yield i, j, self[vec2(i,j)]
      end
    end
  end
end
