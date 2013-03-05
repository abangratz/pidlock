require 'spec_helper'

describe Pidlock do
  let(:logger) { mock(Logger) }
  before(:each) do
    @file = stub(File)
    @file.stub(:flock)
    @file.stub(:write)
    @file.stub(:flock => 0)
    @file.stub(:flush)
    @file.stub(:gets)
    File.stub(:open).with('/var/run/my.pid', File::RDWR|File::CREAT, 0600).and_return(@file)
    File.stub(:writable?).with('/var/run').and_return(true)
    Logger.stub!(:new => logger)
  end
  it "creates a file with the given name in /var/run" do
    Pidlock.new('my.pid').lock
  end
  context "filehandling" do
    before(:each) do
      Process.stub(:pid).and_return(666)
      logger.stub!(:warn)
    end
    it "writes the current pid to the file" do
      @file.should_receive(:write).with(666)
      Pidlock.new('my.pid').lock
    end
    it "uses a directory under /var/run if given" do
      File.should_receive(:open).with("/var/run/my/my.pid",  File::RDWR|File::CREAT, 0600).and_return(@file)
      File.should_receive(:writable?).with("/var/run/my").and_return(true)
      @file.should_receive(:write).with(666)
      Pidlock.new('my/my.pid').lock
    end

    it "tries to lock the file" do
      @file.should_receive(:flock).with( File::LOCK_EX | File::LOCK_NB).and_return(0)
      Pidlock.new('my.pid').lock
    end

    it "raises if the lock does not succeed" do
      @file.should_receive(:flock).with( File::LOCK_EX | File::LOCK_NB).and_return(false)
      lambda {
        Pidlock.new('my.pid').lock
      }.should raise_error Pidlock::FileLockedException
    end

    it "checks if the program name matches the id" do
      @file.should_receive(:gets).and_return('666')
      ps = stub("ProcTableStruct", :comm => 'test')
      ::Sys::ProcTable.should_receive(:ps).with(666).and_return(ps)
      Pidlock.new('my.pid').lock
    end
    it "raises if the program name does match the pid" do
      @file.should_receive(:gets).and_return('666')
      ps = stub("ProcTableStruct", :comm => 'my')
      ::Sys::ProcTable.should_receive(:ps).with(666).and_return(ps)
      lambda {
        Pidlock.new('my.pid').lock
      }.should raise_error Pidlock::ProcessRunning
    end

    it "uses /tmp if /var/run is not writeable" do
      File.should_receive(:writable?).with('/var/run').and_return(false)
      File.should_receive(:open).with('/tmp/my.pid', File::RDWR|File::CREAT, 0600).and_return(@file)
      Pidlock.new('my.pid').lock
    end
    it "warns but continue if the file exists but the process name does not" do
      @file.should_receive(:gets).and_return('667')
      ps = stub("ProcTableStruct", :comm => 'test')
      ::Sys::ProcTable.should_receive(:ps).with(667).and_return(nil)
      logger.should_receive(:warn).with('WARNING: resetting stale lockfile')
      @file.should_receive(:rewind)
      @file.should_receive(:write).with(666)
      Pidlock.new('my.pid').lock
    end
    it "should use a logger if injected" do
      logger2 = mock(Logger)
      @file.should_receive(:gets).and_return('667')
      ps = stub("ProcTableStruct", :comm => 'test')
      ::Sys::ProcTable.should_receive(:ps).with(667).and_return(nil)
      logger.should_not_receive(:warn).with('WARNING: resetting stale lockfile')
      logger2.should_receive(:warn).with('WARNING: resetting stale lockfile')
      @file.should_receive(:rewind)
      @file.should_receive(:write).with(666)
      pidlock = Pidlock.new('my.pid')
      pidlock.logger = logger2
      pidlock.lock
    end
  end
end
