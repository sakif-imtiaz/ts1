module Assets
  class Decoration
    def self.load_all
      $gtk
        .parse_json_file("assets/tiny_swords/Deco/cropped/decorations.json")
        .map do |hsh|
        hsh_l1_sym = hsh.transform_keys(&:to_sym)
        hsh_l1_sym.sprite_params.transform_keys!(&:to_sym)
        hsh_l1_sym.icon_size.transform_keys!(&:to_sym)
        new(**hsh_l1_sym)
      end
    end

    include Arby::Attributes

    attr_accessor :name, :sprite_params, :icon_size, :placer

    def initialize(**kwargs)
      assign!(**kwargs)
    end

    def placed_sprite(position)
      VP::Helpers.sprite(
        **sprite_params,
        x: position.x,
        y: position.y
      )
    end

    def icon_sprite
      VP::Helpers.sprite(
        **sprite_params,
        x: 0,
        y: 0
      )
    end

    def place!(position_hash)
      pos = vec2(position_hash["x"], position_hash["y"])
      placer.place(self, pos)
    end

    private

    def path
      sprite_params.path
    end

    def w
      sprite_params.w
    end

    def h
      sprite_params.h
    end

    def source
      VP::Sprites::Source.new(
        bounds: quick_rect(0, 0,icon_size.w, icon_size.h)
      )
    end

    def cropped_source
      VP::Sprites::Source.new(
        bounds: quick_rect(0, 0,w,h)
      )
    end

    def filename
      @_filename ||= path.split("/").last
    end
  end
end
