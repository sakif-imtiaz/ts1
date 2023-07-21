module Units
  class WalkPath
    attr_reader :unit, :flow_field, :destination, :current_leg

    def self.build(unit, flow_field, destination)
      new(unit, flow_field, destination)
    end

    def initialize(unit, flow_field, destination)
      @unit = unit
      @flow_field = flow_field
      @destination = destination
      @current_leg = nil
      mark_traveled!(unit.foot_position)
    end

    def traveled?(cell)
      traveled[cell.snap(cell_size).with_i.clone]
    end

    def traveled
      @traveled ||= {}
    end

    def mark_traveled!(visited)
      traveled[visited.snap(cell_size).with_i.clone] = true
    end

    def frame_offset
      current_leg.frame_offset
    end

    def advance!
      next_leg! if current_leg.nil? || current_leg.done?
      current_leg.advance! if current_leg
    end

    def next_leg!
      cell_pos = Units::FlowFieldBuilder.
        build_neighbors(unit.foot_position/cell_size, flow_field).
        map { |(_dir, pos)| pos }.
        min_by do |pos|
        [
          traveled?(pos*cell_size) ? 1 : 0,
          Units.manager.obstacles[pos] ? 1 : 0,
          flow_field[pos].best_cost
        ]
      end
      cell_pos = foot_position/cell_size unless cell_pos
      @current_leg = Walk.new(unit, cell_pos * cell_size)
      mark_traveled!(cell_pos * cell_size)
    end

    def done?
      unit.foot_position == destination
    end

    def sprite_params
      current_leg.sprite_params
    end

    def colliders
      current_leg&.colliders
    end

    def cell_size
      self.class.cell_size
    end

    def self.cell_size
      Units::Navigation.cell_size.to_f
    end

    def obstacles
      Units.manager.obstacles
    end
  end

  class WalkSetPath
    attr_reader :unit, :legs

    def self.build(unit, waypoints)
      legs = waypoints.map { |waypoint| Walk.new(unit, waypoint) }
      new(unit, legs)
    end

    def initialize(unit, legs)
      @unit = unit
      @legs = legs
    end

    # def source
    #   current_leg.source
    # end

    def frame_offset
      current_leg.frame_offset
    end

    def current_leg
      legs.last
    end

    def advance!
      legs.pop if current_leg.done?
      current_leg.advance! if current_leg
    end

    def done?
      legs.empty? || (legs.count == 1 && current_leg.done?)
    end

    def sprite_params
      current_leg.sprite_params
    end

    def colliders
      current_leg&.colliders
    end
  end

  class Walk
    include Simple
    attr_reader :unit, :to, :from

    def initialize(unit, to)
      @unit = unit
      @to = to
      @from = unit.board_position.clone
    end

    def advance!
      @elapsed_ticks = elapsed_ticks + 1
      unit.board_position += board_position_delta
      unit.board_position = to if done?
    end

    def board_position_delta
      (to - unit.board_position).normalize * speed
    end

    def speed
      1.0
    end

    def done?
      (to - unit.board_position).mag2 < speed**2
    end

    def animation_config_name
      :walk
    end
    # def source
    #   sheet.source(row, frame_index)
    # end
  end
end
