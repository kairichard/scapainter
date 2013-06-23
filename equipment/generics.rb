require 'ruby-progressbar'
module Equipment
  module Generics

    module Processor
      def initialize(opts)
        @filmstrip = opts[:filmstrip]
        @opts = opts
      end
      def outfile_path(infile_path, outfile_name)
        File.join(File.split(infile_path)[0],outfile_name)
      end
    end

    class ProcessorChain
      include Processor
      attr_accessor :processors

      def initialize(opts = {})
        self.processors = []
        super(opts)
      end

      def process
        p = ProgressBar.create(title: "Postprocessing",total: @filmstrip.frames.count * self.processors.count, format: "%t: |%b>%i| %a %E (%c/%C)")
        self.processors.reduce(@filmstrip.frames.to_a) do |memo,processor|
          memo.map do |frame|
            p.increment
            processor.process(frame)
          end
        end
      end
    end

  end
end
