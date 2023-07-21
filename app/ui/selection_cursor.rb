module UI
  class SelectionCursor
    extend VP::Helpers
    extend Layout::Helpers

    def self.build(rect)
      selection_cursor_source = VP::Sprites::Source.new(bounds: quick_rect(0, 0, 64, 64))
      if (rect.w * rect.h).abs > 0
        Block.new(bounds: quick_bounds(**(rect.to_h))).adopt!(
          Block.new(float: true, bounds: quick_bounds(-30, -30)).adopt!(sprite(path: 'assets/tiny_swords/UI/Pointers/05.png', source: selection_cursor_source)),
          Block.new(float: true, bounds: quick_bounds(-30, '100% -25px')).adopt!(sprite(path: 'assets/tiny_swords/UI/Pointers/03.png', source: selection_cursor_source)),
          Block.new(float: true, bounds: quick_bounds('100% -25px', -30)).adopt!(sprite(path: 'assets/tiny_swords/UI/Pointers/06.png', source: selection_cursor_source)),
          Block.new(float: true, bounds: quick_bounds('100% -25px', '100% -25px')).adopt!(sprite(path: 'assets/tiny_swords/UI/Pointers/04.png', source: selection_cursor_source))
        )
      else
        Block.new
      end
    end
  end

  module Helpers
    def selection_cursor(rect)
      SelectionCursor.build(rect)
    end

    module_function :selection_cursor
  end
end