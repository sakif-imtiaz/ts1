require "matrix_helpers.rb"
require "./app/map/grid.rb"

describe Grid do
  let(:grid) { Grid.build(vec2(5,5)) }

  it "has 25 elements" do
    expect(grid.rows.flatten.count).to eq(25)
  end

  describe "setting" do
    before { grid[vec2(1,1)] = :blue }

    it "paints some" do
      expect(grid[vec2(1,1)]).to eq(:blue)
    end

    it "sets only that one to blue" do
      expect(grid.rows.flatten.compact).to eq([:blue])
    end
  end
end
