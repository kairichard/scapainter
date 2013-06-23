module Utils
  module SatisfyArrangementFromCmdLine
    attr_accessor :arrangement_of_screens

    def arrangement_to_filenames
      self.arrangement_of_screens.split(",").length.times.map{|i| capture_file_name i}
    end

    def arrangement_to_imagemagick_convert_args
      arrangement_of_screens.split(",").map do |a|
        if a.length > 1
          i = a[0]
          background = case a[1]
                       when "t" then "transparent"
                       end
          "#{capture_file_name i} -background #{background}"
        else
          capture_file_name a
        end
      end
    end

    def capture_file_name i
      "capture#{i}.jpg"
    end
  end
end

