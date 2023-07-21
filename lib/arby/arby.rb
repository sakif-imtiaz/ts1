include MatrixFunctions
extend MatrixFunctions

module Arby
	module Attributes
	  def assign!(**kwargs)
	    kwargs.each do |k, v|
	      send("#{k}=".to_sym, v)
	    end
	    self
		end

	  def slice(*attrs)
			attrs.map do |attr|
				[attr, send(attr.to_sym)]
	    end.to_h
		end
	end

	module Vector2
		def positive?
			x > -1 && y > -1
		end

		def snap(to)
			(self/to.to_f).floor.with_i*(to.to_i)
		end

		def not_dim!
			@as_dim = false
			self
		end

		def as_dim?
			@as_dim ||= true
		end

		def clamp(rect)
			vec2(
				x.clamp(rect.x, rect.w + rect.x),
				y.clamp(rect.y, rect.h + rect.y),
			)
		end

		def with_i
			vec2(x.to_i, y.to_i)
		end

		def with_f
			vec2(x.to_f, y.to_f)
		end

		def round
			vec2(x.to_f.round.to_f, y.to_f.round.to_f)
		end

		def ceil
			vec2(x.to_f.ceil.to_f, y.to_f.ceil.to_f)
		end

		def floor
			vec2(x.to_f.floor.to_f, y.to_f.floor.to_f)
		end

		def abs
			vec2(x.abs, y.abs)
		end

		def mag2
			((x**2)+(y**2))
		end

		def mag
			mag2**0.5
		end

		def normalize
			self / mag
		end

		def *(other)
			vec2(
				(x*other).to_f,
				(y*other).to_f,
			)
		end

		def lerp(v2, c)
			v2*(1.0 - c) + self*c
		end

		def manhattan_distance(v2)
			(y - v2.y).abs + (x - v2.x).abs
		end

		def inside_rect?(rect)

			{x: x, y: y, w: 0, h: 0}.inside_rect?(rect.to_h)
		end

		def -(other)
			vec2(
				(x - other.x).to_f,
				(y - other.y).to_f,
			)
		end

		def /(other)
			self * (1.0/other)
		end

		def w
			x if as_dim?
		end

		def w=(other)
			self.x = other
		end

		def h
			y if as_dim?
		end

		def h=(other)
			self.y = other
		end
	end
end

class Array
	def to_json
		insides = map do |v|
			v.to_json
		end.join(", ")
		"[#{insides}]"
	end

	def self.wrap(object)
		if object.nil?
			[]
		elsif object.respond_to?(:to_ary)
			object.to_ary || [object]
		else
			[object]
		end
	end

	def <(other)
		(self <=> other) == -1
	end
end

class Hash
	def to_json
		insides = map do |(k,v)|
			"#{k.to_json}:#{v.to_json}"
		end.join(", ")
		"{#{insides}}"
	end

	def with_syms
		transform_keys do |k|
			k.is_a?(String) ? k.to_sym : k
		end
	end
end

class Numeric
	def ease_in_out(duration, *fxns)
		self.ease(duration, fxns).lerp(
			self.ease(duration, [:flip, *fxns, :flip]),
			self.ease(duration, fxns))
	end

	def to_json
		self
	end
end

class Symbol
	def to_json
		to_s.inspect
	end
end

class String
	def to_json
		inspect
	end
end

class Object
	def to_json
		to_h.to_json
	end

	def try(msg_name, *args, **kwargs)
		if kwargs.any?
			send(msg_name, *args, **kwargs)
		else
			send(msg_name, *args)
		end
	end

	def to_h
		{klass: self.class.name}
	end

	def serialize
		to_h
	end

	def layer
		0
	end
end

class NilClass
	def to_json
		"null"
	end

	def try(*_args, **_kwargs)
		nil
	end
end
