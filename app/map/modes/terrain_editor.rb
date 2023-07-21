class TerrainEditor
  module HandleInputs
    include Pushy::Helpers

    def mouseß!
      @mouse_actionsß ||= Services.mouse.mouse_actions.
        link(filter { |_ma| self.active }).
        subscribe do |ma|
        handle_mouse_action ma
      end

      @clickß ||= Services.mouse.clicks›.
        link(filter { |_click| self.active }).
        subscribe do |click|
        handle_click click
      end

      @dragß ||= Services.mouse.drag›.
        link(filter { |_drag| self.active }).
        subscribe do |click|
        handle_drag click
      end
    end

    def handle_mouse_action mouse_action
      check_export_button!(mouse_action)
    end

    def handle_click(click)
      check_terrain_options!(click)
    end

    def handle_drag(drag)
      check_canvas!(drag)
    end

    def check_export_button! mouse_action
      update_export_button!(mouse_action) if export_button_clicked?(mouse_action)
    end

    def check_terrain_options!(click)
      terrain_options.handle_click!(click)
    end

    def check_canvas!(drag)
      if drag.move? && !drag.middle? && drag.p2.inside_rect?(level_terrain_sprite.bounds)
        pt = GridCalculator.new(vec2(64,64), vec2(64,64)).grid_pt(drag.p2)
        layer_options.selected_grid[pt]= drag.left?
      end
    end
  end

  module ExportButton
    def export_button
      @export_button ||= sprite(
        path: "assets/tiny_swords/UI/Buttons/Button_Blue.png",
        source: VP::Sprites::Source.new(bounds: quick_rect(0,0,64,64)),
        bounds: quick_rect(640,0,64,64)
      )
    end

    def export_button_clicked?(mouse_action)
      mouse_action.point.inside_rect?(export_button.bounds) && mouse_action.left
    end

    def update_export_button!(mouse_action)
      if mouse_action.up
        export_button.path = "assets/tiny_swords/UI/Buttons/Button_Blue.png"
        perform_export!
      elsif mouse_action.down
        export_button.path = "assets/tiny_swords/UI/Buttons/Button_Blue_Pressed.png"
      end
    end
  end

  class App
    extend Forwardable
    def_delegators :@map_app, :layer_options, :terrain_options, :level_terrain_sprite, :decoration_options

    include HandleInputs
    include ExportButton

    attr_reader :map_app
    attr_accessor :active

    def initialize(map_app)
      @map_app = map_app
      @active = false
      mouseß!
    end

    def perform_tick
      render!
    end

    def render!
      $gtk.args.outputs.primitives << [
        terrain_options.layout_component.renderables,
        layer_options.display,
        export_button
      ]
    end

    def perform_export!
      $gtk.write_file("data/base_layer.json", layer_options.layers.base.to_json)
    end
  end
end