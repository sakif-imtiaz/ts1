module Units
  def manager
    @_manager ||= Manager.new()
  end

  def selection_widget
    @_selection_widget ||= SelectedUnits.new(VP::Helpers.rect(vec2(0,0), vec2(64*9, 64*10)))
  end

  module_function :manager, :selection_widget

  class Manager
    attr_reader :units, :selected, :obstacles

    def initialize()
      @selected = []
      @units = []
    end

    def choose_within!(rect)
      @selected = units_within(rect)
    end

    def units_within(rect)
      units.select do |unit|
        unit.selectbox&.intersect_rect?(rect)
      end
    end

    def perform_tick(args)
      build_obstacles!
      units.each(&:advance!)
      handle_collisions!
      cleanup!
      args.outputs.primitives << map(&:board_primitives)
    end

    def handle_collisions!
      units.product(units) do |a,b|
        if a && b && a != b
          hit(a, b)
          # foot(a, b)
        end
      end
    end

    # def foot(a, b)
    #   a.colliders.foot&.perform!(b)
    # end

    def hit(a,b)
      a.colliders.hit&.perform!(b)
    end

    def cleanup!
      if (tick_count % 60) == 0
        units.delete_if(&:expired?)
      end
    end

    def each
      units.each { |u|  yield u }
    end

    def map
      units.map { |u| yield u }
    end

    def tick_count; $gtk.args.state.tick_count; end

    def cell_size
      Navigation.cell_size
    end

    def build_obstacles!
      @obstacles ||= Units.build_cells
      @obstacles.reset_grid!
      units.each do |unit|

        # puts "OVERLAP" if obstacles[(unit.foot_position/(cell_size.to_f)).with_i]
        @obstacles.set!((unit.foot_position/cell_size).with_i, true)
      end
      @obstacles
    end
  end
end



