module VP
  class Volatile
    include Util
    attr_reader :preserve

    def initialize(preserve)
      @preserve = preserve
    end

    def primitive_marker
      :volatile
    end

    def renderables
      @preserve.map { |pr| pr.renderables }
    end

    def to_ary
      @preserve
    end
  end
end

module BuildVolatiles
  def volatile!
    VP::Volatile.new(self)
  end

  def to_ary

  end
end

def soft_flatten(arr, *allowed)
  flattened = []
  arr.each do |element|
    if element.is_a? Array
      flattened.concat(soft_flatten(element, *allowed))
    elsif allowed.any? { |kl| element.is_a?(kl) }
      flattened.concat(soft_flatten(element.to_ary, *allowed))
    else
      flattened << element
    end
  end
  flattened
end

Array.prepend(BuildVolatiles)
