module Equipment
  class Camera
    attr_reader :shots_taken
    attr_accessor :mode, :filmstrip

    def initialize
      @shots_taken = 0
    end

    def insert(filmstrip)
      self.filmstrip = filmstrip
    end

    def screencapture
      cmd = "screencapture -ox #{self.filmstrip.frame.next}"
      %x{#{cmd}}
    end

    def shoot
      @shots_taken = @shots_taken + 1
      self.send(mode)
    end
  end
end
