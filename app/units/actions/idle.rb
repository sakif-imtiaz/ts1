module Units
  class Idle
    include Simple
    attr_reader :unit

    def initialize(unit)
      @unit = unit
    end

    def advance!
      @elapsed_ticks = elapsed_ticks + 1
    end

    def elapsed_ticks
      @elapsed_ticks ||= 0
    end

    def done?
      false
    end

    def animation_config_name
      :idle
    end

    # def source
    #   sheet.source(row, frame_index)
    # end
  end

  class StuckArrow < Idle
    attr_reader :shot_by

    def initialize(unit, shot_by)
      @unit = unit
      @shot_by = shot_by
    end

    def animation_config_name
      :stuck
    end

    def offset
      vec2(64 - 17, 64 - 30)
    end

    def custom_sprite_params
      {
        rotation: VP::Sprites::Rotation.new(
          angle: shot_by.board_position.with_f.angle_to(unit.board_position.with_f),
          position: offset.with_f/64.0
        )
      }
    end
  end
end
