module Assets
  class Sheet
    SHEET_SIZES = {
      "assets/tiny_swords/Terrain/Water/Water2.png" => [64, 64],
      "assets/tiny_swords/Terrain/Ground/Tilemap_Elevation2.png" => [256, 512],
      "assets/tiny_swords/Terrain/Ground/Tilemap_Flat.png" => [640, 256],
      "assets/tiny_swords/Terrain/Ground/Sand.png" => [320, 256],
      "assets/tiny_swords/Terrain/Ground/Grass.png" => [320, 256],
      "assets/tiny_swords/Terrain/Bridge/Bridge_All2.png" => [320, 448],
      "assets/tiny_swords/Terrain/Water/Foam/Foam.png" => [192*8, 192],
      "assets/tiny_swords/Terrain/Water/Rocks/Rocks_01.png" => [128*8, 128],
      "assets/tiny_swords/Terrain/Water/Rocks/Rocks_02.png" => [128*8, 128],
      "assets/tiny_swords/Terrain/Water/Rocks/Rocks_03.png" => [128*8, 128],
    }
    include Arby::Attributes
    # include DB::Persists

    attr_accessor :path, :name, :tile_size, :pack_path

    def initialize(path: nil)
      @path = path
      @full_path = ""
    end

    def full_path
      "#{pack_path}/#{path}"
    end

    def dimensions
      @_dimensions ||= calculate_dimensions
    end

    def calculate_dimensions
      # wh = $gtk.calcspritebox(path)
      # # $gtk.get_pixels(full_path.to_s)
      # puts "wh: #{wh}"
      raise "path size #{path} missing" unless SHEET_SIZES[path]
      vec2(*(SHEET_SIZES[path]))
      # vec2(pixel_array.w, pixel_array.h)
    end

    # def pixel_array
    #   $gtk.get_pixels(full_path.to_s)
    # end

    # def valid?
    #   !!(pixel_array && pixel_array.w && pixel_array.w > 0 && pixel_array.h > 0)
    # end

    def ==(other)
      other && (path == other.path)
    end

    alias_method :eql?, :==

    def hash; [self.class.name, path, pack_path].hash; end

    def to_h
      slice(*[:path, :name, :tile_size, :pack_path])
    end

    def to_s
      to_h.to_s
    end

    def self.from_json(hsh)
      built = new(path: hsh.path)
      built.pack_path = hsh.pack_path
      built.name = hsh.name
      built.tile_size = vec2(hsh.tile_size["w"], hsh.tile_size["h"])
      built
    end

    def to_json; to_h.to_json; end

    def self.db_config
      {
        klass: Assets::Sheet,
        table_name: "sheets",
        column_names: %i(path pack_path name tile_size),
        primary_keys: %i(path pack_path),
        # has: [{
        #   klass: Assets::Slice,
        #   foreign_key: :sheet_path,
        #   own_key: :path
        # },{
        #   klass: Assets::Pack,
        #   foreign_key: :path,
        #   own_key: :pack_path
        # }]
      }
    end
  end
end