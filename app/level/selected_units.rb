class SelectedUnits
  include Pushy::Helpers
  include VP::Helpers
  include Layout::Helpers

  attr_reader :play_rect, :selecting, :selected, :selected_icons

  def initialize play_rect
    @selecting = false
    @play_rect = play_rect
    @selected = []
    @selected_icons = []
    # dragß!
    overlay.render
  end

  # def dragß!
  #   @dragß ||= Services.mouse.drag›.subscribe { |drag| handle_drag(drag) }
  # end

  def contains_drag?(drag)
    drag.rect.p1.inside_rect?(play_rect)
  end

  # def handle_drag(drag)
  #   # I don't love that this is here, but we might be checking for other drags elsewhere
  #   # that are close to this in some way =(
  #   if drag.rect.p1.inside_rect?(play_rect) && drag.left?
  #     update_overlay!(drag)
  #     update_selected_units!(drag)
  #   end
  # end

  def update_icons!
    # return unless drag.end?
    @selected_icons.replace(Units.manager.selected.map do |unit|
      # su_icon.parent = selected_row
      cloned_icon = unit.icon.clone
      puts cloned_icon.to_h
      cloned_icon
    end)
    ui_banner.recalculate!
  end

  def update_overlay!(drag)
    if drag.move?
      @selecting = true
      overlay.place!(drag.rect)
    elsif drag.end? && selecting
      @selecting = false
      overlay.place!(quick_rect(0,0,0,0))
    end
  end

  def overlay
    @overlay ||= Block.new(static: true, data: {name: :selection_overlay}).adopt!(
      solid(color: VP::Color.new([120, 120, 120, 80])),
      hollow_solid(color: VP::Color.new([50, 50, 50, 80]))
    ).tap { |ol| ol.rendering.layer = 10 }
  end

  # def display_selected
  #   @display_selected ||= Row.new(bounds: offset(64*10, 0), sizing: :wrap).tap do |r|
  #     r.children = @selected_icons
  #     r.place!
  #   end
  # end
  def selected_row
    @selected_row ||= Row.new(sizing: :wrap).adopt!([@selected_icons])
  end

  def ui_banner
    @ui_banner ||= UI::Banner.new(
      Block.new(sizing: :wrap).adopt!(selected_row))
  end

  # def selected_units§
  #   @selected_units§ ||= ui_banner
  # end

  def perform_tick(args)
    args.outputs.primitives << [
      overlay.renderables,
      # display_selected.tap(&:place!).renderables
    ]
  end
end
