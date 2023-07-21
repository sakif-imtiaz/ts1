module Nav
  class Node
    attr_reader :rect, :marker, :edges, :graph
    def initialize(rect, marker, graph)
      @graph, @rect, @marker= graph, rect, marker
      @edges = {}
    end

    def cell_coords
      return @_cell_coords if @_cell_coords
      cirect = rect.with_i.canonical
      p1 = cirect.p1.with_i
      p2 = cirect.p2.with_i
      @_cell_coords = ((p1.x)...(p2.x)).to_a.map do |i|
        ((p1.y)...(p2.y)).to_a.map do |j|
          vec2(i, j)
        end
      end.flatten
    end

    def cell_coords_adjacent_to(other_node)
      cell_coords.select do |cc|
        other_node.cell_coords.any? { |occ| cells_adjacent?(cc, occ) }
      end
    end

    def build_edge_with!(other_node)
      raise "edge from #{marker} to #{other_node.marker} already exists" if edges[other_node.marker]
      adjacents = cell_coords_adjacent_to(other_node)
      if adjacents.any?
        edges[other_node.marker] = Edge.new(other_node, adjacents)
      end
    end

    def cells_adjacent?(v1, v2)
      v1.manhattan_distance(v2) == 1
    end
  end
end
