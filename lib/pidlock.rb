class Pidlock


  class FileLockedException < Exception; end
  class ProcessRunning < Exception; end
  def initialize(name)
    @name = File.basename(name)
    @filename = File.join('/', 'var', 'run', @name)
  end

  def lock
    unless @file
      unless (File.writable?(File.dirname(@filename)))
        @filename = File.join('/', 'tmp', @name)
      end
      @file = File.open(@filename, 'w+') 
      if (old_pid = @file.gets)
        if (old_process = Sys::ProcTable.ps(old_pid.chomp.to_i))
          raise ProcessRunning if old_process.comm == File.basename(@name, File.extname(@name))
        else
          STDERR.puts "WARNING: resetting stale lockfile"
          @file.rewind
        end
      end
      @file.flock(File::LOCK_EX | File::LOCK_NB) or raise FileLockedException
      @file.write Process.pid
      @file.flush
    end
  end

end
