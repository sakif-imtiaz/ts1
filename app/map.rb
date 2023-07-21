include MatrixFunctions
extend MatrixFunctions
Vec2.prepend(Arby::Vector2)

module Directions
  RIGHT = vec2(1, 0)
  DOWN = vec2(0, -1)
  LEFT = vec2(-1, 0)
  UP = vec2(0, 1)
end

# "dragonruby . --eval app/game.rb"

class Map
  include Maps::Apps::Terrains
  include Maps::Apps::Decorations

  def setup_services!
    $services_before ||= [Services.mouse]
    $services_after ||= []
  end

  def initialize
    setup_services!
  end

  def perform_tick(args)
    $services_before.each { |service| service.tick(args) } unless args.state.tick_count == 0

    return map_loader.load_next_sublayer! if map_loader.loading?

    args.render_target(:level_terrain).sprites << layer_options.layer_primitives
    args.outputs.sprites << level_terrain_sprite
    args.outputs.sprites << placed_decoration_primitives

    selected_sub_app.perform_tick

    $services_after.each { |service| service.tick(args) }
  end

  def selected_sub_app
    @_sub_apps ||= {
      terrain: TerrainEditor::App.new(self),
      decorations: DecorationsEditor::App.new(self)
    }
    selection = :decorations
    @_sub_apps.each do |(k, v)|
      v.active = (k == selection)
    end
    @_sub_apps[selection]
  end
end
