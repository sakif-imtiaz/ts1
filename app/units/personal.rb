module Units
  module Health
    attr_writer :health
    attr_accessor :party

    def health
      @health ||= full_health
    end

    def expired?
      false
    end

    def full_health
      20.0
    end

    def health_ratio
      health/full_health
    end

    def health_bar
      # healthbox = hurtbox.clone.tap do |hb|
      #   hb.h *= health_ratio
      # end
      #
      # [ solid(color: VP::Color.new([0,200,0, 100]), bounds: healthbox) ]
      []
    end

    def hurtbox
      rect(board_position + vec2(70,60) - offset,
           vec2(54, 58)
      )
    end

    # colliders

    def collider_primitives
      # candidate for module
      colliders.values.compact.map(&:primitives).reduce([], :+)
    end

    def colliders
      {
        hurt: Units::Colliders::Hurt.new(self),
        # foot: GridPositioning::WalkCollider.new(self)
      }
    end
  end


  module GridPositioning
    attr_accessor :board_position
    def cell_size
      Units::Navigation.cell_size.to_f
    end

    def foot_position
      board_position.snap(cell_size)
      # (board_position/cell_size).round * cell_size
    end

    # def personal_space
    #   VP::Helpers.rect(
    #     foot_position - vec2(5,5),
    #     footbox_size + vec2(10,10)
    #   )
    # end
    #
    # def footbox
    #   VP::Helpers.rect(
    #     foot_position,
    #     footbox_size
    #   )
    # end
    #
    # def footbox_size
    #   vec2(cell_size, cell_size)
    # end

    # def colliders
    #   {foot: WalkCollider.new(self)}
    # end

    # def walking?
    #   current_action&.class == WalkPath
    # end

    # class WalkCollider
    #   include Units::Colliders::Collider
    #
    #   def color
    #     # VP::Helpers.color(:alloy_orange)
    #     VP::Color.new([196,98,16, 180])
    #   end
    #
    #   def initialize(unit)
    #     @unit = unit
    #   end
    #
    #   def perform!(other_unit)
    #     return unless unit.walking?
    #     other_footbox = other_unit&.colliders&.foot&.box
    #     return unless other_footbox
    #
    #     if box.intersect_rect?(other_footbox)
    #       unit.current_action.detour! if unit.current_action.next_cell == (other_unit.foot_position/cell_size).with_i
    #     end
    #   end
    #
    #   def cell_size
    #     Units::Navigation.cell_size.to_f
    #   end
    #
    #   def box
    #     unit.personal_space
    #   end
    # end
  end
end
