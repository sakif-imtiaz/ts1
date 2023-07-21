module Units
  TILE_SIZE = 64

  UNIT_COLORS = %i(blue red purple yellow)

  module Animated
    attr_writer :action_queue

    def board_primitives
      [sprite(
         bounds: rect(board_position - offset, dimensions),
         **(current_action.sprite_params)
       ),
       solid(color: color(:red), bounds: rect(board_position - vec2(3,3), vec2(3,3)*2))
      ]
    end

    def advance!
      action_queue.pop if current_action&.done?
      idle! unless current_action
      current_action&.advance!
    end

    def current_action
      action_queue.last
    end

    def start!(action)
      action_queue.clear << action
    end

    def enqueue_action!(action)
      action_queue.push action
    end

    def action_queue
      @action_queue ||= []
    end

    # def board_primitives
    #   [
    #     *board_sprites,
    #     (solid(color: VP::Color.new([0,0,255, 100]), bounds: hurtbox) if hurtbox),
    #     (solid(color: VP::Color.new([255,0,0, 100]), bounds: hitbox) if hitbox)
    #   ].compact
    # end
  end

  module HasIcon
    def icon
      Arranged.new.adopt!(sprite(
                            path: path,
                            bounds: VP::Helpers.rect(vec2(0,0), dimensions).with_f,
                            source: VP::Sprites::Source.new(
                              bounds: VP::Helpers.rect(
                                idle_frame_position,
                                dimensions
                              ).with_f
                            )
                          ))
    end

    def idle_frame_position
      vec2(0, animation_configs.idle.row*dimensions.h).with_f
    end

  end

  class AssetOptionFactory
    include Arby::Attributes
    attr_accessor :color, :icon_offset, :icon_size

    def self.build_colors(sheet_module, **kwargs)
      UNIT_COLORS.map do |color|
        build(sheet_module, color: color, **kwargs)
      end
    end

    def self.build(sheet_module, **kwargs)
      new(**kwargs).extend(sheet_module).build
    end

    def initialize(**kwargs)
      assign!(**kwargs)
    end

    def sprite_params
      offsetted_idle_frame = idle_frame_position + icon_offset
      {
        path: path,
        x: 0, y: 0, w: icon_size.w, h: icon_size.h,
        source_x: offsetted_idle_frame.x,
        source_y: offsetted_idle_frame.y,
        source_w: icon_size.w,
        source_h: icon_size.h,
      }
    end

    def name
      [model, color].compact.join("_")
    end

    def build
      Assets::Decoration.new(
        name: name,
        sprite_params: sprite_params,
        icon_size: icon_size
      )
    end
  end

  module Helpers
    def troop_sheet(faction, model, color)
      "assets/tiny_swords/Factions/#{faction.capitalize}/Troops/#{model.capitalize}/#{color.capitalize}/#{model.capitalize}_#{color.capitalize}.png"
    end

    module_function :troop_sheet
  end

  module AssertAction
    def source
      raise "units need to be able to get to a sprite source that represents what they're doing right now"
    end

    def done?
      raise "an action should be able cue its own dismissal"
    end

    def advance!
      raise "actions can depend on several things, but those things are determined before it takes a step in time. so it should be able to #advance! without more args"
    end
  end
end