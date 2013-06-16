require 'main'
require 'paint'
require 'paint/pa'
require 'open3'
require "debugger"

def capture_file_name i
  "capture#{i}.jpg"
end

def arrangement_to_filenames args
  args.split(",").length.times.map{|i| capture_file_name i}
end

def arrangement_to_imagemagick_convert_args args
  args.split(",").map do |a|
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

def pout *args
  print Paint[*args]
end

Main {
  keyword('arr') {
    required
    defaults "0"
    cast :string
  }

  mode "test" do
    mode "arrangement" do
      def run
        arrangement = params["arr"].value
        screenshot_files = arrangement_to_filenames arrangement
        `screencapture -ox #{screenshot_files.join " "}`
        `convert #{arrangement_to_imagemagick_convert_args(arrangement).join " "} +append  'output.png'`
        `open output.png`
      end
    end
  end

  mode "capture" do
    keyword('time'){
        attr do |param|
          value, unit = param.value.split ""
          case unit
            when "h" then value.to_i * 3600
            when "m" then value.to_i * 60
            else value.to_i
          end
        end
    }
    keyword('step-width') {
      required
      cast :int
    }
    keyword('total-width'){
      required
      cast :int
    }
    keyword('height'){
      required
      cast :int
      attr
    }
    def run
      step_width = params["step-width"].value
      total_width= params["total-width"].value
      intial_interval = time / ( total_width / step_width )
      pout "Recalculation interval ... ", :blue
      pout(" [ ",:white); pout("Done", :green); pout(" ] ",:white)
      puts ""
    end
  end
}
