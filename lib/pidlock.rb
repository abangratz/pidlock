require 'logger'
require 'fileutils'

class Pidlock

  attr_accessor :logger

  class FileLockedException < Exception; end
  class ProcessRunning < Exception; end
  
  def initialize(name)
    dir = File.dirname(name)
    @name = File.basename(name)
    @filename = File.expand_path(File.join('/', 'var', 'run', dir, @name))
    @logger = Logger.new(STDERR)
  end



  def lock
    unless @file
      unless (File.writable?(File.dirname(@filename)))
        @filename = File.join('/', 'tmp', @name)
      end
      @file = File.open(@filename, File::RDWR|File::CREAT, 0600) 
      if (old_pid = @file.gets)
        if (old_process = Sys::ProcTable.ps(old_pid.chomp.to_i))
          raise ProcessRunning if old_process.comm == File.basename(@name, File.extname(@name))
        else
          @logger.warn "WARNING: resetting stale lockfile"
          @file.rewind
        end
      end
      @file.flock(File::LOCK_EX | File::LOCK_NB) or raise FileLockedException
      @file.write Process.pid
      @file.flush
    end
  end

  def unlock
    @file.close
    FileUtils.rm_f(@filename)
  end

end
