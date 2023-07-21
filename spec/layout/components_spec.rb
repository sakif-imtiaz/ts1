require "./spec/matrix_helpers.rb"
require "./lib/visual-primitives/sprite.rb"
require "./spec/layout/components.rb"


describe Components do
  include Components::Helpers
  include VP::Helpers

  let(:tree) do
    $named = {}
    parent(name: 1).around!(
      sprite(color: "yellow"),
      parent(name: 2, layout: layout(offset: offset(20, 20), size: size(40, 60))).around!(sprite(path: "green")),
      hollow_solid(path: "blue"),
      wrapper(name: 3, layout: layout(placement: placements.row)).around!(
        parent(name: 4, layout: layout(size: {w: 120, h: 80})).around!(sprite(path: "white")),
        parent(name: 5, layout: layout(size: {w: 120, h: 80})).around!(sprite(path: "orange"))
      )
    )
  end

  it "collects things from the bottom up" do
    names = []
    tree.bottom_up do |component|
      names << component.name
    end

    expect(names).to eq([2,4,5,3,1])
  end

  it "collects primitives in order" do
    paths = []
    tree.bottom_up do |component|
      paths.concat(component.primitive_children.map(&:path))
    end

    expect(paths).to eq(%w(green white orange yellow blue))
  end

  describe "steps" do
    let(:tree) do
      parent(name: 1).around!(
        solid(color: color(:yellow)),
        parent(name: 2, layout: layout(offset: offset(20, 20), size: size(40, 60))).around!(
          sprite(color: color(:emerald))),
        hollow_solid(color: color(:navy_blue)),
        wrapper(name: 3, layout: layout(placement: placements.row)).around!(
          parent(name: 4, layout: layout(size: size(120, 80))).around!(solid(color: color(:white))),
          parent(name: 5, layout: layout(size: size(120, 80))).around!(solid(color: color(:alloy_orange)))
        )
      )
    end

    describe "" do

    end
  end
end
