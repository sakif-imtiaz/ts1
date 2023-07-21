module Units
  module Pawns
    ROWS = [
      { flip_horizontally: false},
      { flip_horizontally: true },
    ]
  end
  class Chop
    include Simple
    attr_reader :unit, :at

    def initialize(unit, at)
      @unit, @at = unit, at
    end

    def advance!
      @elapsed_ticks = elapsed_ticks + 1
    end

    def done?
      elapsed_frames >= frame_count
    end

    def hitbox
      unit.hurtbox.nudge(midstroke_direction*50.0)
    end

    def animation_config_name
      :chop
    end

    def midstroke_direction
      (at - unit.board_position).normalize
    end

    def angle
      unit.board_position.with_f.angle_to(at.with_f)
    end

    def rounded_angle
      ((angle + 90)/180.0).floor % 2
    end

    def direction_params
      Pawns::ROWS[rounded_angle].clone
    end

    def custom_sprite_params
      {rotation: VP::Sprites::Rotation.new(flip_horizontally: direction_params.flip_horizontally) }
    end

    def colliders
      @_colliders ||= { hit: Units::Colliders::Chop.new(unit, self) }
    end
  end
end
