module Maps
  module Apps
    module Decorations
      def placed_decoration_primitives
        load_placed_decorations! unless decorations_loaded
        placed_decorations.map(&:renderables)
      end

      def decoration_options
        @_decoration_options ||= (plain_decoration_options + unit_options)
      end

      private

      # loading/initializing options

      def unit_options
        @_unit_options ||= [
          Units::Archers,
          Units::Warriors,
          Units::Pawns,
          Units::Trees
        ].map(&:build_asset_options).
          reduce(:+).
          each { |unit_option| unit_option.placer = unit_placer }
      end

      def plain_decoration_options
        @_plain_decoration_options ||= Assets::Decoration.
          load_all.
          each { |decoration| decoration.placer = inert_placer }
      end

      # initializing

      def placed_decorations
        @placed_decorations ||= []
      end

      attr_writer :decorations_loaded

      def decorations_loaded
        @decorations_loaded ||= false
      end

      def load_placed_decorations!
        self.decorations_loaded = true
        DecorationsEditor::PlacedDecoration.load_all("data/placed_decorations.json", decoration_options)
      end

      # placer helpers

      def if_in_game(game_value, editor_value)
        $my_game.is_a?(Game) ? game_value : editor_value
      end

      def canvas_offset_from_board
        if_in_game(CURRENT_CANVAS_OFFSET_FROM_WINDOW_ORIGIN*0.75, vec2(0,0))
      end

      module_function :if_in_game, :canvas_offset_from_board

      # placers

      def inert_placer
        @_inert_placer ||= InertPlacer
      end

      class InertPlacer
        def self.place(option, position)
          to_place = ::DecorationsEditor::PlacedDecoration.new(option, position - Decorations.canvas_offset_from_board)
          $my_game.placed_decorations << to_place
        end
      end

      def unit_placer
        # yes I could address this with polymorphism but I kinda wanna keep this code here
        # with its buddies for right now.
        return @_unit_placer if @_unit_placer
        @_unit_placer = Decorations.if_in_game(UnitPlacer, inert_placer)
      end

      class UnitPlacer
        MODEL_TO_KLASS = {
          :archer => Units::Archers::Archer,
          :pawn => Units::Pawns::Pawn,
          :warrior => Units::Warriors::Warrior,
          :tree => Units::Trees::Tree,
        }

        def self.place(option, position)
          model, color = *(option.name.to_s.split('_').map(&:to_sym))
          color = color&.to_sym
          unit_args = [ position.snap(Units::GRID_SIZE) - Decorations.canvas_offset_from_board, color].compact
          unit = MODEL_TO_KLASS[model].new(*unit_args)
          unit.party = color
          Units.manager.units << unit
        end
      end
    end

    module Terrains
      def layer_options
        @_layer_options ||= LayerOptions.build_with_same_terrain_options(terrain_options)
      end

      def terrain_options
        return @_terrain_options if @_terrain_options
        @_terrain_options = TerrainOptions.new(tof.all_terrains, :water)# tof.build(tof.all_terrains.map(, start: :water)
      end

      def tof
        @_tof ||= TerrainOptionFactory.new
      end

      def level_terrain_sprite
        @_leveL_terrain_sprite ||= sprite(
          path: :level_terrain,
          bounds: quick_rect(TILE_W, TILE_H, TILE_W*MAP_TILE_W, TILE_H*MAP_TILE_H),
          source: VP::Sprites::Source.new(
            bounds: quick_rect(0,0, TILE_W*MAP_TILE_W, TILE_H*MAP_TILE_H),
            )
        )
      end

      def map_loader
        @_map_loader ||= MapLoader.new(
          "data/base_layer.json",
          layer_options.layers.base.grid,
          terrain_options,
          tof
        )
      end
    end
  end
end