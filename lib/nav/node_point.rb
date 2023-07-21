module Nav
  class NodePoint
    attr_reader :node, :position

    def initialize(node, position)
      @node = node
      @position = position
    end
  end

  class Edge
    attr_reader :to, :adjacent_cells
    def initialize(to, adjacent_cells)
      @to = to
      @adjacent_cells = adjacent_cells
    end
  end
end
