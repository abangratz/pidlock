class Pidlock


  class FileLockedException < Exception; end
  class ProcessRunning < Exception; end
  def initialize(name)
    @name = File.basename(name)
    @filename = File.join('/', 'var', 'run', 'x', @name)
  end

  def lock
    unless @file
      @file = File.open(@filename, 'w+') 
      if (old_pid = @file.gets)
        old_process = Sys::ProcTable.ps(old_pid.chomp.to_i)
        raise ProcessRunning if old_process.comm == File.basename(@name, File.extname(@name))
      end
      @file.flock(File::LOCK_EX | File::LOCK_NB) or raise FileLockedException
      @file.write Process.pid
      @file.flush
    end
  end

end
