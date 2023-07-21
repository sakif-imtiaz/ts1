
module Inputs
  def intake
    @_intake ||= Inputs::Intake.new
  end
  module_function :intake

  class Intake
    include Pushy::Helpers

    def initialize
      @_dragß = Services.mouse.drag›.subscribe { |drag| DragCommands.handle(drag) }
      @_clickß = Services.mouse.clicks›.subscribe { |drag| ClickCommands.handle(drag) }
    end
  end

  class NullCommand
    def run!

    end
  end
end