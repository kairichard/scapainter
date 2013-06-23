require 'main'
require 'paint'
require 'paint/pa'
require 'open3'
require 'FileUtils'
require 'debugger'
require 'shellwords'
$:.unshift File.dirname(__FILE__)
require 'equipment'
require 'utils'

class ArrangementProcessor
  include Equipment::Generics::Processor

  def process(item)
    path_to_items = File.split(item.split(" ")[0])[0]
    path_of_items_to_convert = @filmstrip.arrangement_to_imagemagick_convert_args.map do |c|
      File.join(path_to_items, c)
    end.join(" ")
    outfile_path = File.join(path_to_items, "output.png")
    cmd = "convert #{path_of_items_to_convert} +append  '#{outfile_path}'"
    system(cmd)
    outfile_path
  end
end


class ResizeProcessor
  include Equipment::Generics::Processor

  def process(infile_path)
    outfile_path = self.outfile_path(infile_path,"resized.png")
    cmd = "convert #{infile_path} -resize #{@opts[:step_width]}x#{@opts[:height]}! '#{outfile_path}'"
    system(cmd)
    outfile_path
  end
end


class SoftenHighLowKeyProcessor
  include Equipment::Generics::Processor

  def process(infile)
    outfile = File.join(File.split(infile)[0],"softend.png")
    cmd = "convert #{infile}  "+
      "( -clone 0 -blur 0x60 ) "+
      "( -clone 0 -clone 1 +swap -compose mathematics "+
      "-set option:compose:args '0,1,-1,0.5' -composite "+
      "-matte -channel A -evaluate set 40% +channel ) "+
      "( -clone 0 -blur 0x3 ) "+
      "( -clone 0 -clone 3 +swap -compose mathematics "+
      "-set option:compose:args '0,1,-1,0.5' -composite "+
      "-matte -channel A -evaluate set 50% +channel ) "+
      "( -clone 0 -clone 2 -compose hardlight -composite "+
      "-clone 4 -compose overlay -composite ) "+
      "-delete 0-4 a.png"

    system Shellwords.escape(cmd)
    outfile
  end
end


class ScreencaptureFilmstrip
  include Equipment::Filmstrip
  include Utils::SatisfyArrangementFromCmdLine

  attr_reader :store_path

  def initialize(opts)
    @store_path = opts[:store_path]
    self.arrangement_of_screens = opts[:arrangement_of_screens]
    super
  end

  def prepare
    @directories = @length.times.to_a.map{|d| File.join(@store_path, ("%04d" % d))}
    @directories.each do |directory|
      FileUtils.makedirs(directory)
    end
    @frames = @directories.map do |directory|
      self.arrangement_to_filenames.map{|f| File.join(directory, f)}.join(" ")
    end
    @frame = @frames.enum_for :each
  end
end


class CaptureSession
  attr_accessor :idle_threshold, :camera
  attr_reader :shots_needed

  def initialize(opts)
    opts.default_proc = lambda{|h,v| raise Exception.exception(v)}
    @step_width = opts[:step_width]
    @total_width= opts[:total_width]
    @finish_at = Time.at(Time.now.to_i + opts[:time])

    @shots_taken = 0
    @shots_needed = @total_width / @step_width

    self.camera = opts[:camera]
    @p = ProgressBar.create(title: "Capturing", total: @shots_needed, format: "%t: |%b>%i| %a %E (%c/%C)")
    self.idle_threshold = 10
  end

  def capture
    while self.camera.shots_taken < @shots_needed do
      self.take_screenshot if not idle?
      sleep(self.calculate_interval)
    end
  end

  def take_screenshot
    self.camera.shoot
    @p.increment
  end

  def idle?
    `idler`.to_i >= self.idle_threshold
  end

  def time_left
    time_left = @finish_at.to_i - Time.now.to_i
    time_left > 0 ? time_left  : 0
  end

  def calculate_interval
    @interval = (self.time_left.to_f / @shots_needed.to_f).round(2)
  end
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
        p = params

        camera = Equipment::Camera.new
        camera.mode = :screencapture

        strip = ScreencaptureFilmstrip.new(
          length: 1,
          arrangement_of_screens: p["arr"].value,
          store_path: ".")

        camera.insert strip
        camera.shoot

        outfile = ArrangementProcessor.new(filmstrip: strip).process(strip.frames.first)
        `open #{outfile}`
      end
    end
  end

  mode "capture" do
    keyword('time'){
      attr do |param|
        unit = param.value[-1]

        case unit
        when "h" then param.value[0..-2].to_i * 3600
        when "m" then param.value[0..-2].to_i * 60
        else param.value.to_i
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
    keyword("store-path"){
      optional
      default "./session_#{Time.now.to_i}"
    }
    def run
      p = params


      camera = Equipment::Camera.new
      camera.mode = :screencapture

      session = CaptureSession.new(
        camera: camera ,
        step_width: p["step-width"].value,
        total_width: p["total-width"].value,
        time: time,
        screen_arrangement: p["arr"].value
      )

      strip = ScreencaptureFilmstrip.new(
        length: session.shots_needed,
        arrangement_of_screens: params["arr"].value,
        store_path: p["store-path"].value)
      session.camera.insert strip
      session.capture

      chain = Equipment::Generics::ProcessorChain.new(filmstrip: strip)
      chain.processors.push(
          ArrangementProcessor.new(filmstrip: strip),
          ResizeProcessor.new(height: height, step_width: p["step-width"].value),
      )
      outfile_paths = chain.process

      puts "Combining all Files"
      `convert #{outfile_paths.join " "} +append #{File.join(strip.store_path, "result.png")}`

    end
  end
}
