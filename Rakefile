namespace :vendor do
  task :install do |t, args|
    Dir.chdir "vendor"
    Dir.glob(File.join("**","Makefile")).each do |e|
        Dir.chdir e.split("/").first
        system "make && make install"
        Dir.chdir ".."
    end
  end
end
