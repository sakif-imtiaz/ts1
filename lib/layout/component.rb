module Layout
  module Composers
    class Onto
      def self.place!(component)
        rect = component.current_rect
        children = component.children
        return unless children.any?
        chidx = 0
        moving_rect = rect.clone
        while chidx < children.count
          children[chidx].place!(parent_rect: moving_rect.clone)
          chidx += 1
        end

        merged = children.reduce(quick_rect(rect.x,rect.y,0.0,0.0)) do |memo_merged, child|
          memo_merged.merge(child.current_rect)
        end
        component.current_rect = merged
      end
    end

    class Row
      def self.place!(component)
        rect = component.current_rect
        children = component.children
        return unless children.any?
        chidx = 0
        moving_rect = rect.clone
        while chidx < children.count
          children[chidx].place!(parent_rect: moving_rect.clone)
          moving_rect.x = moving_rect.x + children[chidx].current_rect.w
          chidx += 1
        end
        component.current_rect.w = moving_rect.x - rect.x

        children_p2s = children.
          map(&:current_rect).
          map(&:canonical).
          map(&:p2)

        component.current_rect.h = children_p2s.map(&:y).
          max - rect.y

=begin
alternative calc
        children_crects = children.
          map(&:current_rect).
          map(&:canonical)
        children_p1s = children_crects.map(&:p1)
        children_p2s = children_crects.map(&:p2)

        component.current_rect.h = children_p2s.map(&:y).
          zip(children_p1s).map(&:y).
          max - rect.y
=end
      end
    end

    class Column
      def self.place!(component)
        rect = component.current_rect
        children = component.children
        return unless children.any?
        chidx = 0
        moving_rect = rect.clone
        while chidx < children.count
          children[chidx].place!(parent_rect: moving_rect.clone)
          moving_rect.y = moving_rect.y + children[chidx].current_rect.h
          chidx += 1
        end
        component.current_rect.h = moving_rect.y - rect.y
        children_p2s = children.
          map(&:current_rect).
          map(&:canonical).
          map(&:p2)

        component.current_rect.w = children_p2s.map(&:x).
          max - rect.x
      end
    end
  end

  class Component
    # this is supposed to be the thing we slice out of component that contains "children"
    # based on that, it may contain other things, such as parent or whatever, but the idea is that
    # it doesn't contain the bounds config, but rather recieves messages from its derivative
    include Helpers
    include Pushy::Helpers
    attr_reader :composer, :children
    attr_accessor :current_rect

    def initialize(*children, bounds: quick_bounds, composer: Composers::Onto)
      @children = children

      @composer = composer
      @rx_bounds = RxBounds.new(bounds)
      @rx_bounds.bounds›.subscribe do |cb|
        self.place!(current_bounds: cb)
      end
      @current_parent_rect = VP::Helpers.window_rect
      # register
    end

    # Concering how components contain children

    def renderables
      children.map do |child|
        if child.primitive_marker
          child
        else
          child.renderables
        end
      end
    end

    def component_children
      children.
        flatten.
        select { |c| !c.primitive_marker }
    end

    def primitive_marker
      nil
    end

    # Concering how components layout their children

    def bounds
      @rx_bounds
    end

    def current_bounds
      @rx_bounds.bounds
    end

    def place!(parent_rect: @current_parent_rect, current_bounds: @rx_bounds.bounds)
      @current_parent_rect = parent_rect
      return unless @current_parent_rect && current_bounds
      @current_rect = current_bounds.against(parent_rect)
      composer.place!(self)
      rect›.next(current_rect)
    end

    def link!(parent_rect›)
      @_linkß = parent_rect›.subscribe { |pr| place!(parent_rect: pr) }
      self
    end

    def rect›
      @rect ||= observable
    end

    def hide!
      @rx_bounds.hide!
      self
    end

    def unhide!
      @rx_bounds.unhide!
      self
    end
  end

  module Helpers
    def component(*children, **kwargs)
      Component.new(*children, **kwargs)
    end

    def row(*children, **kwargs)
      Component.new(*children, **kwargs, composer: Composers::Row)
    end

    def column(*children, **kwargs)
      Component.new(*children, **kwargs, composer: Composers::Column)
    end

    module_function :component, :row, :column
  end
end
