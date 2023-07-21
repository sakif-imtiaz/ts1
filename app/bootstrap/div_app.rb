class DivApp
  attr_reader :root, :root_offsetter, :swatch_wrapper, :swatches

  include VP::Helpers
  include Layout::Helpers

  def perform_tick(args)
    [tree, uilc].each do |w|
      w.place!
      args.outputs.primitives << w.renderables
    end
  end

  def uilc
    @ui = UI::Banner.example
    @uilc = Block.new(bounds: offset('50%', '50px')).adopt!(
      @ui.layout_component,
      Block.new(float: true).adopt!(hollow_solid(color: :sandstorm))
    )
  end

  def tree
    @root = Block.new(data: {hide_label: true})

    @swatches = Row.new(
      sizing: :wrap,
      bounds: quick_bounds(30, 30, '100% 30px', '100% 30px'),
      data: {label_position: :top_right}
    ).adopt!(
      build_swatch(:carnation_pink),
      build_swatch(:cornflower_blue),
      build_swatch(:aqua),
      hollow_solid(color: :dark_orange)
    )

    @swatch_wrapper = Block.new(
      sizing: :wrap,
      bounds: offset(40, 40)
    ).adopt!(
      solid(color: :light_green),
      hollow_solid(color: :pine_green),
      Block.new(bounds: quick_bounds('30%', '30px', '40%', '100% -30px'),
                float: true).
        adopt!(solid(color: :navy_blue)
      ),
      swatches,
    )

    @root_offsetter = Block.new(
      sizing: :wrap, bounds: offset(50, 80), data: {name: :root_offsetter}
    ).adopt!(
      solid(color: :light_gray),
      hollow_solid(color: :gray),
      swatch_wrapper
    )

    @root.adopt!(
      @root_offsetter
    )
    @root
  end

  SWATCH_SIZE = 80

  def ramp
    0 # (8 - ($gtk.args.state.tick_count >> 2) % 16).abs
  end

  def build_swatch(color_name)
    Block.new(bounds: size(120, 80 + ramp)).adopt!(
      solid(color: color_name),
      hollow_solid(color: color(color_name).darken(0.7))
    )
  end
end
