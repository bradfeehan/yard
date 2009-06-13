require 'rubygems/specification'
require 'rubygems/doc_manager'
require File.dirname(__FILE__) + '/yard' unless defined?(YARD)

class Gem::Specification
  # has_rdoc should not be ignored!
  overwrite_accessor(:has_rdoc) { @has_rdoc }
  overwrite_accessor(:has_rdoc=) {|v| @has_rdoc = v }
  
  def self.has_yardoc=(value)
    @has_rdoc = 'yard'
  end
  
  def has_yardoc
    @has_rdoc == 'yard'
  end
  
  def has_rdoc?
    @has_rdoc && @has_rdoc != 'yard'
  end
  
  alias has_yardoc? has_yardoc
end

class Gem::DocManager
  def run_yardoc(*args)
    args << @spec.rdoc_options
    args << '--quiet'
    if @spec.extra_rdoc_files.size > 0
      args << '--files'
      args << @spec.extra_rdoc_files.join(",")
    end
    args << @spec.require_paths.map {|p| p + "/**/*.rb" }
    args = args.flatten.map do |arg| arg.to_s end

    old_pwd = Dir.pwd
    Dir.chdir(@spec.full_gem_path)
    YARD::CLI::Yardoc.run(*args)
  rescue Errno::EACCES => e
    dirname = File.dirname e.message.split("-")[1].strip
    raise Gem::FilePermissionError.new(dirname)
  rescue RuntimeError => ex
    alert_error "While generating documentation for #{@spec.full_name}"
    ui.errs.puts "... MESSAGE:   #{ex}"
    ui.errs.puts "... YARDDOC args: #{args.join(' ')}"
    ui.errs.puts "\t#{ex.backtrace.join "\n\t"}" if
    Gem.configuration.backtrace
    ui.errs.puts "(continuing with the rest of the installation)"
  ensure
    Dir.chdir(old_pwd)
  end

  def setup_rdoc
    if File.exist?(@doc_dir) && !File.writable?(@doc_dir) then
      raise Gem::FilePermissionError.new(@doc_dir)
    end

    FileUtils.mkdir_p @doc_dir unless File.exist?(@doc_dir)

    self.class.load_rdoc if @spec.has_rdoc?
  end

  def install_yardoc
    rdoc_dir = File.join(@doc_dir, 'rdoc')

    FileUtils.rm_rf rdoc_dir

    say "Installing YARD documentation for #{@spec.full_name}..."
    run_yardoc '-o', rdoc_dir
  end

  def install_ri_yard
    install_ri_yard_orig if @spec.has_rdoc?
  end
  alias install_ri_yard_orig install_ri
  alias install_ri install_ri_yard
  
  def install_rdoc_yard
    if @spec.has_rdoc?
      install_rdoc_yard_orig
    elsif @spec.has_yardoc?
      install_yardoc
    end
  end
  alias install_rdoc_yard_orig install_rdoc
  alias install_rdoc install_rdoc_yard
end