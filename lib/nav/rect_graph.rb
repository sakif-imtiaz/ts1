# require "matrix_helpers.rb"
# require "./app/map/grid.rb"
# require "./lib/nav/node.rb"
# require "./lib/nav/node_point.rb"

module Nav
  class RectGraph
    attr_reader :dimensions, :grid, :nodes
    def initialize(dimensions)
      @dimensions = dimensions
      @grid = Grid.build(self.dimensions, vec2(1,1))
      @nodes = {}
    end

    def paint!(rect)
      new_node = Node.new(rect, nodes.values.count, self)
      nodes.each { |(k, on)| on.build_edge_with!(new_node) }
      nodes.each { |(k, on)| new_node.build_edge_with!(on) }
      @nodes[new_node.marker] = new_node
      grid.assign_slice!(rect.with_i) do |_i, _j, contents|
        raise "already taken" if contents
        new_node
      end
    end

    def to_s
      grid.visible_slice.rows.transpose.map do |row|
        row.map { |c| c.nil? ? "_" : c.marker }.join("")
      end.reverse
    end

    def print
      puts to_s.join("\n")
    end

    def [](vec)
      grid[vec]
    end

    def path_cache
      @_path_cache ||= PathCache.new(self)
    end

    def path_between(rv1, rv2)
      v1, v2 = rv1.with_f / 64.0, rv2.with_f / 64.0

      walkable = path_cache[self[v1].marker] && self[v2]
      path_exists = walkable && path_cache[self[v1].marker][self[v2].marker]

      return [] unless walkable
      return [rv2] if self[v2].marker == self[v1].marker
      return [] unless path_exists

      intermediate_tiles(v1, v2).
        reverse.
        map { |tile_point| tile_point * 64.0 }.
        unshift(rv2)
    end

    def intermediate_tiles(v1, v2)
      ([*path_cache[self[v1].marker][self[v2].marker], self[v2].marker].reduce([]) do |waypoints,marker|
        next_node = nodes[marker]
        prev_waypoint_grid_corner = waypoints.last ? waypoints.last[:grid_corner] : v1
        prev_waypoint_walk_corner = waypoints.last ? waypoints.last[:walk_point] : v1
        prev_node = self[prev_waypoint_grid_corner]
        nearest_cell = nearest(out_of: next_node.edges[prev_node.marker].adjacent_cells, to: prev_waypoint_walk_corner)
        nearest_cell_corners = build_corners([nearest_cell])
        nearest_cell_corner = nearest(out_of: nearest_cell_corners, to: prev_waypoint_walk_corner)
        next_waypoint = { grid_corner: nearest_cell, walk_point: nearest_cell_corner }
        [*waypoints, next_waypoint]
      end).map { |ch| ch[:walk_point] }
    end

    def build_corners(cells)
      cells.map do |cell|
        [cell, cell + vec2(0,0.5), cell + vec2(0.5, 0), cell + vec2(0.5,0.5)]
      end.flatten
    end

    def manhattan_distance(v1, v2)
      (v1.y - v2.y).abs + (v1.x - v2.x).abs
    end

    def nearest(out_of:, to:)
      out_of.min_by { |c| c.manhattan_distance(to) }
    end

    class PathCache
      attr_reader :paths, :graph

      def initialize(graph)
        @graph = graph
        @paths = {}
        expand_until_unchanged!
      end

      def expand_until_unchanged!
        @change_sentinel = nil
        while @change_sentinel.nil? || @change_sentinel == true
          @change_sentinel = false
          expand!
        end
      end

      def expand!
        graph.nodes.values.each.with_index do |n, i|
          n_edge_nodes = n.edges.values.map(&:to)
          n_edge_nodes.each do |ne|
            set_edge(n, ne)
            set_edge(ne, n)
          end
        end
        self
      end

      def [](marker)
        paths[marker] ||= {}
      end

      def set_edge(a, b)
        if self[a.marker][b.marker] != []
          @change_sentinel = true
          self[a.marker][b.marker] = []
        end

        (paths.keys - [a.marker, b.marker]).each do |k|
          if self[k][a.marker]
            existing = self[k][b.marker]
            update_to = if existing
              [
                [*self[k][a.marker], a.marker],
                existing
              ].min_by(&:count)
            else
              [*self[k][a.marker], a.marker]
            end
            @change_sentinel = true unless update_to == existing
            self[k][b.marker] = update_to
          end
        end
      end
    end
  end
end