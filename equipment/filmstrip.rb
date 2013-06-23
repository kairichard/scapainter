module Equipment
  module Filmstrip
    attr_reader :frames, :frame

    def initialize(opts)
      @length = opts[:length]
      self.prepare
    end
  end
end
