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
end
