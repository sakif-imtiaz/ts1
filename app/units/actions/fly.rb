module Units
  class ArrowFly < Walk
    def advance!
      @elapsed_ticks = elapsed_ticks + 1
      unit.board_position += board_position_delta
    end

    def angle
      @angle ||= unit.shot_by.board_position.with_f.angle_to(to.with_f)
    end

    def speed
      # 0.5
      8
    end

    def offset
      vec2(64 - 10, 64 - 34)
    end

    def animation_config_name
      :fly
    end

    def custom_sprite_params
      {
        rotation: VP::Sprites::Rotation.new(
          angle: angle,
          position: offset.with_f/64.0
        )
      }
    end

    def colliders
      @_colliders ||= { hit: Units::Colliders::ArrowHit.new(unit) }
    end
  end
end
