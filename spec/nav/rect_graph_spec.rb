require "matrix_helpers.rb"
require "./app/map/grid.rb"
require "./lib/nav/node.rb"
require "./lib/nav/node_point.rb"
require 'byebug'
require "./lib/nav/node.rb"
require "./lib/nav/node_point.rb"
require "./lib/nav/rect_graph.rb"

describe Nav::RectGraph do
  let(:dims) { vec2(3,3) }
  let(:rect_graph) { Nav::RectGraph.new(dims) }
  let(:printout) { rect_graph.to_s }

  describe "paint!" do
    context "when empty" do
      it "prints an empty grid" do
        expect(printout).to eq(%w[___ ___ ___])
      end
    end

    context "paint a corner" do
      before { rect_graph.paint!(VP::Helpers.quick_rect(0,0,2,2)) }
      it "prints a grid w 0s" do
        expect(printout).to eq(%w[___ 00_ 00_])
      end
    end

    context "painting 2 corners" do
      before do
        rect_graph.paint!(VP::Helpers.quick_rect(0,0,2,2))
        rect_graph.paint!(VP::Helpers.quick_rect(2,1,1,2))
      end

      it "prints a grid w 0s and 1s" do
        expect(printout).to eq(%w[__1 001 00_])
      end
    end
  end

  describe "connections" do
    let(:dims) { vec2(10,10) }
    let(:n0) { rect_graph.nodes[0] }
    let(:e01) { e01.edges[1] }
    before do
      rect_graph.paint!(VP::Helpers.quick_rect(0,0, 3,2))
      rect_graph.paint!(VP::Helpers.quick_rect(3,1, 3,2))
    end

    it "node 0 has an edge with r1" do
      expect(rect_graph.nodes.count).to eq(2)
    end

    it "you can find a node from the grid" do
      expect(rect_graph.grid[vec2(1,1)]).to eq(n0)
    end

    it "n0 has an edge with n1" do
      expect(n0.edges.keys).to eq([1])
    end

    it "n0 has an edge with n1" do
      expect(n0.edges.keys).to include(1)
    end

    describe "path_cache" do
      let(:n1) {rect_graph.nodes[1] }
      let(:n2) {rect_graph.nodes[2] }
      let(:n3) {rect_graph.nodes[3] }
      let(:start_np) { Nav::NodePoint.new(n0, vec2(0,1)) }
      let(:dest_np) { Nav::NodePoint.new(n3, vec2(8,0)) }

      before do
        rect_graph.paint!(VP::Helpers.quick_rect(6,2, 2,4))
        rect_graph.paint!(VP::Helpers.quick_rect(5,0, 4,1))
        rect_graph.paint!(VP::Helpers.quick_rect(0,5, 6,3))
        rect_graph.paint!(VP::Helpers.quick_rect(0,2, 1,3))
        rect_graph.paint!(VP::Helpers.quick_rect(5,8, 2,2))
      end

      xit "prints out" do
        puts "\n"
        rect_graph.print
        puts "\n"
        true
      end

      it "has an edge between 1 and 3" do
        expect(n3.edges[1]).to be_truthy
        expect(n1.edges[3]).to be_truthy
      end

      describe "path cache" do
        let(:path_cache) { rect_graph.path_cache }

        it "has a path from 0 3" do
          expect(
            rect_graph.path_between(vec2(6,9), vec2(6,0)).any?
          ).to be_truthy
        end
      end
    end
  end
end
