module Units
  module Archers
    ROWS = [
      { row: 2, flip_horizontally: false, arrowhead_corner_offset: vec2(132, 105) },
      { row: 3, flip_horizontally: false, arrowhead_corner_offset: vec2(120, 71) },
      { row: 4, flip_horizontally: false, arrowhead_corner_offset: vec2(107, 42) },
      { row: 3, flip_horizontally: true , arrowhead_corner_offset: vec2(120, 71)},
      { row: 2, flip_horizontally: true , arrowhead_corner_offset: vec2(132, 105) },
      { row: 1, flip_horizontally: true , arrowhead_corner_offset: vec2(117, 131)},
      { row: 0, flip_horizontally: false, arrowhead_corner_offset: vec2(86, 143) },
      { row: 1, flip_horizontally: false, arrowhead_corner_offset: vec2(117, 131) }
    ]
  end

  class Shoot
    include Simple
    attr_reader :unit, :at

    def initialize(unit, at)
      @unit, @at = unit, at
    end

    def advance!
      @elapsed_ticks = elapsed_ticks + 1
      spawn_arrow! if elapsed_ticks == 5
    end

    def spawn_arrow!
      initial_arrow_position = unit.board_position - sheet.offset + direction_params.arrowhead_corner_offset
      arrow = Units::Arrows::Arrow.new(initial_arrow_position, unit)
      Units.manager.units << arrow
      arrow.enqueue_action! Units::ArrowFly.new(arrow, at)
    end

    def done?
      elapsed_frames >= frame_count
    end

    def animation_config_name
      :shoot
    end

    def midstroke_direction
      (unit.board_position - at).normalize
    end

    def angle
      unit.board_position.with_f.angle_to(at.with_f)
    end

    def rounded_angle
      ((angle + 22.5)/45.0).floor % 8
    end

    def row
      direction_params.row
    end

    def direction_params
      Archers::ROWS[rounded_angle]
    end

    def custom_sprite_params
      {rotation: VP::Sprites::Rotation.new(flip_horizontally: direction_params.flip_horizontally) }
    end
  end
end
