module Units
  module Warriors
    ROWS = [
      { row: 4, flip_horizontally: false},
      { row: 0, flip_horizontally: false},
      { row: 4, flip_horizontally: true },
      { row: 2, flip_horizontally: false},
    ]
  end
  class Slash
    include Simple
    attr_reader :unit, :at, :backhand

    def initialize(unit, at, backhand: false)
      @unit, @at = unit, at
      @backhand = backhand
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
      :slash
    end

    def midstroke_direction
      (at - unit.board_position).normalize
    end

    def angle
      unit.board_position.with_f.angle_to(at.with_f)
    end

    def rounded_angle
      ((angle + 45.0)/90.0).floor % 4
    end

    def row
      direction_params.row
    end

    def direction_params
      Warriors::ROWS[rounded_angle].clone.tap do |forehand_params|
        forehand_params.row += 1 if backhand
      end
    end

    def custom_sprite_params
      {rotation: VP::Sprites::Rotation.new(flip_horizontally: direction_params.flip_horizontally) }
    end

    def colliders
      @_colliders ||= { hit: Units::Colliders::SlashHit.new(unit, self) }
    end
  end
end
