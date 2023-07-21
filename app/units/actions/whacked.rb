module Units
  class Whacked
    include Simple
    attr_reader :unit

    def initialize(unit)
      @unit = unit
    end

    def advance!
      @elapsed_ticks = elapsed_ticks + 1
    end

    def elapsed_ticks
      @elapsed_ticks ||= 0
    end

    def done?
      elapsed_frames == 3
    end

    def animation_config_name
      :whacked
    end
  end
end
