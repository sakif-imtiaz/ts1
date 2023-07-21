class DecorationsEditor
  module HandleInputs
    include Pushy::Helpers

    def mouseß!
      @mouse_actionsß ||= Services.mouse.mouse_actions.
        link(filter { |_ma| self.active }).
        subscribe do |ma|
        handle_mouse_action ma
      end

      @dragß ||= Services.mouse.drag›.
        link(filter { |_drag| self.active }).
        subscribe do |click|
        handle_drag click
      end

      @clickß ||= Services.mouse.clicks›.
        link(filter { |_click| self.active }).
        subscribe do |click|
        handle_click click
      end
    end

    def handle_mouse_action mouse_action
      check_export_button!(mouse_action)
    end

    def check_export_button! mouse_action
      update_export_button!(mouse_action) if export_button_clicked?(mouse_action)
    end

    def handle_drag(drag)
      check_decoration_drag_and_drop!(drag)
    end

    def handle_click(click)
      check_remove_decoration!(click)
    end
  end

  module AddingDecorations
    attr_reader :selected_decoration

    def check_decoration_drag_and_drop!(drag)
      return unless drag.left? && decorations_widget
      if drag.start? && drag.p1.inside_rect?(decorations_widget.layout_component.current_rect)
        swatch = decorations_widget.swatches.find( -> { nil }) { |swatch| drag.p1.inside_rect?(swatch.layout_component.current_rect) }
        return unless swatch
        @selected_decoration = swatch.asset
      elsif drag.move? && selected_decoration && drag.p2.inside_rect?(level_terrain_sprite.bounds)
        $gtk.args.outputs.primitives << selected_decoration.placed_sprite(drag.p2- CURRENT_CANVAS_OFFSET_FROM_WINDOW_ORIGIN)
      elsif drag.end? && drag.p2.inside_rect?(level_terrain_sprite.bounds)
        return unless selected_decoration
        placed_decorations << PlacedDecoration.new(selected_decoration, drag.p2 - CURRENT_CANVAS_OFFSET_FROM_WINDOW_ORIGIN)
        @selected_decoration = nil
        # $gtk.args.gtk.set_cursor nil
      end
    end

    def check_remove_decoration!(click)
      return unless click.right? && decorations_widget
      matching_decorations = placed_decorations.select do |placed_decoration|
        click.up.point.inside_rect?(placed_decoration.bounds)
      end

      matching_decorations.each { |matching_decoration| placed_decorations.delete matching_decoration }
    end
  end

  class DecorationSwatch
    attr_reader :asset

    def initialize(asset)
      @asset = asset
    end

    def layout_component
      @_layout_component ||= Block.new(
        bounds: Layout::Helpers.quick_bounds(0,0, asset.icon_size.w, asset.icon_size.h),
        ).adopt!(asset.icon_sprite)
    end
  end

  class PlacedDecoration
    attr_reader :asset, :position

    def initialize(asset, position)
      @asset = asset
      @position = position
    end

    def to_h
      board_position = position
      { name: asset.name, position: { x: board_position.x, y: board_position.y } }
    end

    def bounds
      renderables.first.bounds
    end

    def to_json
      to_h.to_json
    end

    def renderables
      [asset.placed_sprite(position)]
    end

    def self.load_all(path, decoration_options)
      $gtk.parse_json_file(path).
        map { |decoration_hash| decoration_hash.transform_keys(&:to_sym) }.
        each do |placed_decoration_params|
          found_asset_option = decoration_options.find( -> { nil }) do |decoration_option|
            decoration_option.name.to_sym == placed_decoration_params.name.to_sym
          end
          found_asset_option&.place!(placed_decoration_params.position)
        end
    end
  end

  class DecorationsWidget
    attr_reader :all_swatches, :swatches

    def self.build(decoration_assets, updated_filter›)
      new(decoration_assets.map do |decoration_asset|
        DecorationSwatch.new(decoration_asset)
      end, updated_filter›)
    end

    def initialize(swatch_options, updated_filter›)
      @all_swatches = swatch_options
      @swatches_layout_components = []
      @swatches = []
      update_swatches!(nil)
      @updated_filter› = updated_filter›
      @updated_filterß = @updated_filter›.link(Pushy::Helpers.changed).subscribe do |query|
        update_swatches!(query)
      end
    end

    def column
      @_column ||= Column.new(sizing: :wrap).adopt!(@swatches_layout_components)
    end

    def banner
      @_banner ||= UI::Banner.new(column)
    end

    def layout_component
      @_layout_component ||= Block.
        new(bounds: bounds).
        adopt!(banner.layout_children).tap(&:place!)
    end

    def update_swatches!(query)
      if query
        @swatches.replace(
          @all_swatches.filter { |swatch| swatch.asset.name.include?(query) })
      else
        @swatches.replace(@all_swatches.first(5))
      end
      @swatches_layout_components.replace(@swatches.map(&:layout_component))
      banner.recalculate!
      layout_component.place!
    end

    private

    def bounds
      Layout::Helpers.quick_bounds(64*10 + 30, 64)
    end
  end

  class App
    extend Forwardable
    def_delegators :@map_app, :level_terrain_sprite, :placed_decorations, :decoration_options

    include HandleInputs
    include AddingDecorations
    include ::TerrainEditor::ExportButton

    attr_reader :map_app
    attr_accessor :active

    def initialize(map_app)
      @map_app = map_app
      @active = false
      mouseß!
    end

    def perform_tick
      render!
      decorations_query›.next(current_decorations_query)
    end

    def render!
      $gtk.args.outputs.primitives << [
        decorations_widget.layout_component.renderables,
        export_button,
      ]
    end

    def perform_export!
      $gtk.write_file("data/placed_decorations.json", placed_decorations.to_json)
    end

    def decorations_widget
      @_decorations_widget ||= DecorationsWidget.build(decoration_options, decorations_query›)
    end

    def current_decorations_query
      "red"
    end

    def decorations_query›
      @_decorations_query› ||= Pushy::Helpers.observable
    end
  end
end