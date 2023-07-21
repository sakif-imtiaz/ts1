module Units
  GRID_SIZE = 32

  module Navigation
    FlowPath = Struct.new(:path, :field)

    def path_between(from, to)
      gridded_to = (to/cell_size).with_i
      gridded_from = (from/cell_size).with_i
      grid = flow_field.build!(to)
      legs = []
      while legs.last != gridded_to
        legs << (grid[(legs.last || gridded_from)].direction + (legs.last || gridded_from)).with_i
      end
      ([from] + legs.map{ |leg| leg * cell_size }).reverse
    end

    def flow_field
      @_flow_field ||= FlowField.new(test_costs, cell_size)
    end

    def cell_size; GRID_SIZE; end
    module_function :cell_size

    def print_flow_field!(grid)
      $gtk.args.render_target(:flow_field).primitives.clear

      $gtk.args.render_target(:flow_field).primitives << grid.map do |cell, i, j|
        # print "#{cell.best_cost} "
        # print "\n" if j == 0
        next unless cell.direction && cell.best_cost < 200
        angle = Math.atan2(cell.direction.y, cell.direction.x)*180/Math::PI
        # puts "angle #{angle}"
        center = vec2(i + 0.5,j)*cell_size
        [
          sprite(
            path: "assets/tiny_swords/Factions/Knights/Troops/Archer/Arrow/Arrow.png",
            source: VP::Sprites::Source.new(bounds: VP::Helpers.quick_rect(0, 64, 64, 64)),
            bounds: VP::Helpers.rect(center, vec2(32,32)),
            rotation: VP::Sprites::Rotation.new(angle: angle, position: vec2(0, 0.5))
          ),
          # text_label(text: cell.best_cost.to_i, x: i*cell_size, y: j*cell_size, size_enum: -2, font: nil)
        ]
      end
    end
    module_function :print_flow_field!

    def test_costs
      @test_costs ||= Units::CostsBuilder.
        new(map_setup.map_loader.terrain_layer, cell_size).
        build!.
        costs
    end
  end

  class FlowField
    attr_reader :costs, :grid, :cell_size
    attr_accessor :to

    def initialize(costs, cell_size)
      @costs = costs
      @cell_size = cell_size
    end

    def build!(to)
      @to = (to/cell_size).with_i
      @grid = FlowFieldBuilder.build!(self).grid
    end
  end

  class FlowFieldBuilder
    extend Forwardable

    def_delegators :@field, :costs, :cell_size, :to

    attr_reader :field, :grid
    attr_accessor :frontier_stack

    def self.build!(field)
      new(field).build!
    end

    def initialize(field)
      @field = field
      @grid = Grid.build(costs.dimensions, vec2(0,0)) do |i, j|
        if vec2(i,j) == to
          { explored: false, direction: nil, best_cost: 0, cost: 0 }
        else
          { explored: false, direction: nil, best_cost: Float::INFINITY, cost: self.field.costs[vec2(i,j)] }
        end
      end
      @frontier_stack = [to]
    end

    def self.dirs
      @@_dirs ||= [-1, 0, 1].product([-1, 0, 1]).map do |(x,y)|
        vec2(x, y)
      end
    end

    def dirs
      self.class.dirs
    end

    def build_frontier(center)
      dirs.
        map { |dir| center + dir }.
        filter do |out|
        out.positive? && out.x < grid.dimensions.x && out.y < grid.dimensions.y && !(grid[out].explored)
      end
    end

    def self.build_neighbors(center, grid)
      dirs.
        map { |dir| [dir, center + dir] }.
        filter do |(_dir, out)|
        out.positive? && out.x < grid.dimensions.x && out.y < grid.dimensions.y #&& (grid[out].explored)
      end
    end

    def build_neighbors(center)
      self.class.build_neighbors(center, grid)
    end

    def build!
      while frontier_stack.any?
        current_frontier = frontier_stack
        current_frontier.each do |pos|
          evaluate!(pos)
        end

        self.frontier_stack = current_frontier.map do |pos|
          build_frontier(pos)
        end.flatten.uniq
      end
      self
    end

    def evaluate!(pos)
      ev = grid[pos]
      ev.explored = true
      build_neighbors(pos).each do |(dir, out)|
        neb = grid[out]
        if ev.best_cost + euclidean_cost(dir, neb.cost) < neb.best_cost
          neb.best_cost = ev.best_cost + euclidean_cost(dir, neb.cost)
          neb.direction = (dir * -1).with_i
          neb.explored = false
        end
      end
    end

    def euclidean_cost(dir, cost_out)
      return Float::INFINITY unless cost_out
      factor = (dir.abs.x + dir.abs.y).clamp(0, 1.41)
      # puts "factor #{factor.inspect}"
      # puts "cost_out #{cost_out.inspect}"
      factor*cost_out
    end
  end

  def terrain_padding

    # padding we assume to be on terrain layer
    vec2(2,2)
  end


  def cell_splits
    (TILE_SIZE/Navigation.cell_size).to_i
  end

  def build_cells(terrain_layer = $my_game.map_setup.map_loader.terrain_layer)
    grid_dims = (terrain_layer.grid.dimensions - terrain_padding*2).tap do |cgw|
      cgw.w = cell_splits * cgw.w
      cgw.h = cell_splits * cgw.h
    end

    Grid.build(grid_dims, vec2(0,0))
  end

  module_function :build_cells, :terrain_padding, :cell_splits

  class CostsBuilder
    attr_reader :terrain_layer, :costs, :cell_size

    def initialize(terrain_layer, cell_size)
      @cell_size = cell_size
      @terrain_layer = terrain_layer
      # cost_grid_dims = (terrain_layer.grid.dimensions - padding*2).tap do |cgw|
      #   cgw.w = cell_splits * cgw.w
      #   cgw.h = cell_splits * cgw.h
      # end
      #
      # @costs = Grid.build(cost_grid_dims, vec2(0,0))
      @costs = Units.build_cells(terrain_layer)
    end

    def padding
      # padding we assume to be on terrain layer
      vec2(2,2)
    end

    def build!
      unpadded_terrain_layer_grid_rect = terrain_layer.grid.visible_rect.
        nudge(padding).
        stretch(padding*-2)
      terrain_layer.grid.for_slice(unpadded_terrain_layer_grid_rect) do |i,j, cell|
        corner = (vec2(i,j) - padding)*cell_splits

        set_for_split_out_cell!(corner, cell)
      end
      self
    end

    def cell_splits
      (TILE_SIZE/cell_size).to_i
    end

    def split_out_offsets
      @split_out_offsets ||= (0...cell_splits).to_a.map do |is|
        (0...cell_splits).to_a.map do |js|
          vec2(is, js)
        end
      end.flatten
    end

    def set_for_split_out_cell!(corner, cell)
      split_out_offsets.each do |split_out_offset|
        costs.set!(corner + split_out_offset, cost(cell))
      end
    end

    def cost(cell)
      cell.walkable? ? 1 : 255
    end
  end
end
