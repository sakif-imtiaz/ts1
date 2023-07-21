# include MatrixFunctions
# extend MatrixFunctions
# Vec2.prepend(Arby::Vector2)

class Game
  include VP::Helpers
  include Maps::Apps::Decorations

  def setup_services!
    $services_before ||= [Services.mouse, Services.typing]
    $services_after ||= [Services.primitive_buffer]
  end

  def initialize
    setup_services!
    Inputs.intake
  end

  def widget
    @widget ||= Row.new.adopt!(
      map_setup.map_component,
      child_providers: [Units.selection_widget.ui_banner]
    ).tap(&:place!)
  end

  def perform_tick(args)
    $services_before.each { |service| service.tick(args) } unless args.state.tick_count == 0
    return map_setup.step!(args) unless map_setup.done?
    widget.render(root: true)

    args.outputs.primitives << placed_decoration_primitives # this loads units too, hmm, that's not so great TODO: smell

    Units.manager.perform_tick(args)
    # render_flow_field_sprite!
    args.outputs.primitives << args.gtk.current_framerate_primitives
    $services_after.each { |service| service.tick(args) }
  end

  def render_flow_field_sprite!
    $gtk.args.render_target(:flow_field).clear_before_render = false
    # return unless $gtk.args.render_target(:flow_field).primitives.any?
    $gtk.args.outputs.primitives << sprite(
      path: :flow_field,
      bounds: quick_rect(0, 0, TILE_W*MAP_TILE_W, TILE_H*MAP_TILE_H),
      source: VP::Sprites::Source.new(
        bounds: quick_rect(0,0, TILE_W*MAP_TILE_W, TILE_H*MAP_TILE_H),
        ),
      layer: 5
    )
  end

  def map_setup; @map_setup ||= MapSetup.new; end

  def nav_graph; map_setup.nav_graph; end

  def waypoints; @waypoints ||= []; end

  include Units::Navigation
end
