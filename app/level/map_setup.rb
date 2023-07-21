class MapSetup
  BASE_LAYER_DATA_PATH = "data/base_layer.json"

  LOADING_SUBLAYERS = 0
  RENDERING_MAP = 1
  REGIONALIZING = 2
  FILL_NAV_GRAPH = 3

  attr_reader :load_state, :map_loader, :regionalizer

  def initialize
    @load_state = LOADING_SUBLAYERS
  end

  def step!(args)
    case load_state
    when LOADING_SUBLAYERS
      map_loader.load_next_sublayer!
      advance! unless map_loader.loading?
    when RENDERING_MAP
      # args.outputs.static_sprites << (map_loader.terrain_layer.primitives)
      @map_component = Arranged.new(static: true, sizing: :wrap, data: { name: :map_component }).
        adopt!(map_loader.terrain_layer.primitives)
      advance!
    when REGIONALIZING
      regionalizer.load_todos!
      regionalizer.process!
      advance!
    when FILL_NAV_GRAPH
      regionalizer.rects.each do |r|
        nav_graph.paint!(r)
      end
      advance!
    end
  end

  def map_component
    @map_component
  end

  def done?
    load_state == 4
  end

  def advance!
    @load_state += 1
  end

  def map_loader
    @_map_loader ||= MapLoader.new(BASE_LAYER_DATA_PATH)
  end

  def regionalizer
    @_regionalizer ||= Regionalizer.new(map_loader.terrain_layer)
  end

  def nav_graph
    @_nav_graph ||= Nav::RectGraph.new(map_loader.terrain_layer.grid.dimensions)
  end
end