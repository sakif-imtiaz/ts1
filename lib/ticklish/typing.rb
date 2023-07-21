$clipboard = ""

module Services
  def typing
    @@typing_instance ||= Typing.new
  end
  module_function :typing

  KEY_MAP = {
    space: " ",
    tab: "  ",
    exclamation_point: "!",
    at: "@",
    hash: "#",
    dollar_sign: "$",
    percent_sign: "%",
    carat: "^",
    ampersand: "&",
    asterisk: "*",
    open_round_brace: "(",
    close_round_brace: ")",
    open_curly_brace: "{",
    close_curly_brace: "}",
    open_square_brace: "[",
    close_square_brace: "]",
    one: "1",
    two: "2",
    three: "3",
    four: "4",
    five: "5",
    six: "6",
    seven: "7",
    eight: "8",
    nine: "9",
    zero: "0",
    colon: ":",
    semicolon: ";",
    equal_sign: "=",
    hyphen: "-",
    backtick: "``",
    tilde: "~",
    period: ".",
    comma: ",",
    pipe: "|",
    underscore: "_",
    double_quotation_mark:"\"",
    single_quotation_mark:"'",
    plus: "+",
    forward_slash: "/",
    back_slash: "/",
    less_than: "<",
    greater_than: ">",
    question_mark: "?",
  }

  class TextInput
    include Arby::Attributes
    include Pushy::Helpers
    attr_accessor :text, :selection, :font, :size_enum
    attr_reader :focus_inputß, :state›

    def initialize(focus›: ,text: "", selection: 0...0, font: "fonts/Vera.ttf", size_enum: 1)
      @text, @selection = text, ((text.size)..(text.size)) || selection
      @font, @size_enum = font, size_enum
      enter_focus›(focus›)
      @state› = observable
      @focus_inputß = Services.typing.keydown›.chain(gate(focus›)).subscribe do |k|
        k.call(self)
        emit_state!
      end
    end

    def emit_state!
      state›.next(self.state)
    end

    class TextState
      include Arby::Attributes
      ATTRS = %i(text cursor_offset selection_offset)
      attr_accessor *ATTRS
      def initialize(**kwargs)
        self.assign!(**kwargs)
      end
    end

    def state
      TextState.new(**(slice(:text, :cursor_offset, :selection_offset)))
    end

    def enter›
      return @_enter› if @_enter›
      @_enter› = observable
      enter_focus›.register(@_enter›)
      @_enter›
    end

    def enter_focus›(focus› = nil)
      @_enter_focus› ||= observable.chain(gate(focus›))
    end

    def enter!(override = nil)
      if override
        enter›.next(override)
      else
        enter_focus›.next(text.clone)
      end
    end

    def cursor
      selection.end
    end

    def sorted_selection
      Range.new(*([@selection.begin, @selection.end].sort), true)
    end

    def set_cursor(c, shift: false)
      @selection = (shift ? @selection.begin : c)...(c)
      cursor
    end

    def cancel_selection!
      @selection = (cursor)...(cursor)
    end

    def width(str)
      $gtk.calcstringbox(str, size_enum, font)[0]
    end

    def cursor_x
      width(text[0...cursor])
    end

    def cursor_offset
      { x: cursor_x }
    end

    def selection_dir
      selection.end > selection.begin ? 1 : -1
    end

    def selection_offset
      selection_dims
    end

    def selection_dims
      return { x: cursor_x, w: 0 } if sorted_selection.size.zero?
      if selection_dir == 1
        { x: cursor_x - width(text[sorted_selection]), w: width(text[sorted_selection]) }

      else
        { x: cursor_x, w: width(text[sorted_selection]) }
      end
    end
  end

  class Typing
    include Pushy::Helpers
    attr_reader :held, :keydown›

    def initialize
      @keydown› = observable
      @held = Press.new([])
    end

    def tick(args)
      held = args.inputs.keyboard.keys[:held]
      down = args.inputs.keyboard.keys[:down]
      if down.any?
        ks = TextStep.new(down, held).to_next
        ks.each { |k| keydown›.next(k) }
      end
      if held
        @held = Press.new(held)
      else
        @held = Press.new([])
      end
    end
  end

  class Commands
    def self.next_char(char, upcase: false); NextChar.new(char, upcase: upcase); end
    def self.paste; NextChar.new($clipboard, upcase: false); end
    def self.cut; Cut.new; end
    def self.copy; Copy.new; end
    def self.backspace; Backspace.new; end
    def self.delete; Delete.new; end
    def self.move_cursor(dir:, by: :char, shift: false)
      MoveCursor.new(dir: dir, by: by, shift: shift)
    end

    def self.enter; ->(ti) { ti.enter! }; end
  end

  class MoveCursor
    attr_reader :dir, :by, :shift
    def initialize(dir: 1, by: :char, shift: false)
      @dir, @by, @shift = dir, by, shift
    end

    ALPHANUMERIC = 48..122

    def by_num(text, cursor)
      if by == :char
        dir
      elsif by == :line
        if dir == 1
          text.length - cursor
        else
          dir * cursor
        end
      elsif by == :word
        if dir == 1
          offset = text[(cursor+1)..-1].split('').find_index { |c| !ALPHANUMERIC.cover?(c.ord)} || (text[cursor..-1].length - 2)
          offset + 1
        else
          offset = (text[0...(cursor - 1)].reverse.split('').
            find_index { |c| !ALPHANUMERIC.cover?(c.ord)}) || cursor
          -1*offset - 1
        end
      else
        0
      end
    end

    def call(ti)
      ti.set_cursor(ti.cursor + by_num(ti.text, ti.cursor), shift: shift)
      ti.set_cursor(ti.cursor.clamp(0, ti.text.size), shift:shift)
      ti.cancel_selection! unless shift
    end
  end

  class NextChar
    def initialize(char, upcase:)
      @char = KEY_MAP.fetch(char, char.to_s)
      @char.upcase! if upcase
    end

    def call(ti)
      Delete.new.call(ti) unless ti.sorted_selection.size.zero?
      charlen = @char.length
      ti.text.insert(ti.cursor, @char)
      ti.set_cursor ti.cursor + charlen
      ti.cancel_selection!
    end
  end

  class Backspace
    def call(ti)
      if ti.sorted_selection.size.zero?
        unless ti.cursor.zero?
          ti.text.slice!(ti.cursor - 1, 1)
          ti.set_cursor ti.cursor - 1
        end
      else
        Delete.new.call(ti)
      end
    end
  end

  class Delete
    def call(ti)
      if ti.sorted_selection.size.zero?
        unless ti.cursor == ti.text.length
          ti.text.slice!(ti.cursor, 1)
        end
      else
        ti.text.slice!(ti.sorted_selection)
        ti.set_cursor ti.sorted_selection.begin
        ti.cancel_selection!
      end
    end
  end

  class Copy
    def call(ti)
      tiss = ti.sorted_selection
      $clipboard = ti.text[tiss] unless tiss.size.zero?
    end
  end

  class Cut
    def call(ti)
      tiss = ti.sorted_selection
      unless tiss.size.zero?
        $clipboard = ti.text[tiss]
        Delete.new.call(ti)
      end
    end
  end

  class TextStep
    def initialize(down, held)
      @down, @held = Press.new(down), Press.new(held)
    end

    def move_by(held)
      if held.alt?
        :word
      elsif held.meta?
        :line
      else
        :char
      end
    end

    def to_next
      if down.char?
        down.keyset.map do |down_char_sym|
          if down.is?(:backspace)
            Commands.backspace
          elsif down.is?(:delete)
            Commands.delete
          elsif down.is?(:left, :right)
            dir = down.is?(:left) ? -1 : 1
            Commands.move_cursor(dir: dir, shift: held.shift?, by: move_by(held) )
          elsif down.is?(:enter)
            Commands.enter
          elsif held.meta?
            case down_char_sym
              when :c
                Commands.copy
              when :x
                Commands.cut
              when :v
                Commands.paste
            end
          else
            Commands.next_char(down_char_sym, upcase: held.shift?)
          end
        end
      else
        []
      end
    end

    private

    attr_reader :down, :held
  end

  class Press
    FULL_EXTRACTABLES = %i(char raw_key)
    EXTRACTABLE_PREFIXES = %i(shift meta alt control)

    (FULL_EXTRACTABLES + EXTRACTABLE_PREFIXES).each do |sym|
      define_method("#{sym}?".to_sym) { instance_variable_get("@#{sym}".to_sym) }
    end

    attr_reader :keyset

    def initialize(keyset_uc)
      keyset = keyset_uc.clone

      FULL_EXTRACTABLES.each do |sym|
        matching = keyset.select { |k| k == sym }
        keyset = keyset - matching
        instance_variable_set("@#{sym}".to_sym, matching )
      end

      EXTRACTABLE_PREFIXES.each do |sym|
        matching = keyset.select { |k| k.to_s.start_with?(sym.to_s) }
        instance_variable_set("@#{sym}".to_sym, matching&.first )
        keyset = keyset - matching
      end
      @keyset = keyset
    end

    def is?(*syms)
      syms.any? do |sym|
        keyset.find { |k| k == sym }
      end
    end
  end
end
