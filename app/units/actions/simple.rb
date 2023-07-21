module Units
  module Simple
    def elapsed_ticks
      @elapsed_ticks ||= 0
    end

    def sheet
      unit
    end

    def animation_configs
      sheet.animation_configs[animation_config_name]
    end

    def row
      animation_configs.row
    end

    def frame_count
      animation_configs.frame_count
    end

    def frame_duration
      animation_configs.frame_duration
    end

    def elapsed_frames
      (elapsed_ticks / frame_duration).to_i
    end

    def frame_index
      start_frame + (elapsed_frames % frame_count).to_i
    end

    def start_frame
      animation_configs.start_frame || 0
    end

    def frame_offset
      vec2(
        sheet.dimensions.w * frame_index,
        sheet.dimensions.h * row
      ).with_f
    end

    def hitbox
      nil
    end

    def source
      VP::Sprites::Source.new(
        bounds: VP::Helpers.rect(
          frame_offset,
          sheet.dimensions
        ).with_f
      )
    end

    def sprite_params
      {
        source: source,
        path: sheet.path
      }.merge(custom_sprite_params)
    end

    def custom_sprite_params
      {}
    end

    # Colliders
    def colliders
      {}
    end
  end
end
