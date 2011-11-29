require 'spec_helper'

describe Pidlock do
  before(:each) do
    @file = stub(File)
    @file.stub(:flock)
    @file.stub(:write)
    @file.stub(:flock => 0)
    @file.stub(:flush)
    @file.stub(:gets)
    File.stub(:open).with('/var/run/my.pid', 'w+').and_return(@file)
    File.stub(:writable?).with('/var/run').and_return(true)
  end
  it "should create a file with the given name in /var/run" do
    Pidlock.new('my.pid').lock
  end
  context "filehandling" do
    before(:each) do
      Process.stub(:pid).and_return(666)
    end
    it "should write the current pid to the file" do
      @file.should_receive(:write).with(666)
      Pidlock.new('my.pid').lock
    end

    it "should try to lock the file" do
      @file.should_receive(:flock).with( File::LOCK_EX | File::LOCK_NB).and_return(0)
      Pidlock.new('my.pid').lock
    end

    it "should raise if the lock does not succeed" do
      @file.should_receive(:flock).with( File::LOCK_EX | File::LOCK_NB).and_return(false)
      lambda {
        Pidlock.new('my.pid').lock
      }.should raise_error Pidlock::FileLockedException
    end

    it "should check if the program name matches the id" do
      @file.should_receive(:gets).and_return('666')
      ps = stub("ProcTableStruct", :comm => 'test')
      ::Sys::ProcTable.should_receive(:ps).with(666).and_return(ps)
      Pidlock.new('my.pid').lock
    end
    it "should raise if the program name does match the pid" do
      @file.should_receive(:gets).and_return('666')
      ps = stub("ProcTableStruct", :comm => 'my')
      ::Sys::ProcTable.should_receive(:ps).with(666).and_return(ps)
      lambda {
        Pidlock.new('my.pid').lock
      }.should raise_error Pidlock::ProcessRunning
    end

    it "should use /tmp if /var/run is not writeable" do
      File.should_receive(:writable?).with('/var/run').and_return(false)
      File.should_receive(:open).with('/tmp/my.pid', 'w+').and_return(@file)
      Pidlock.new('my.pid').lock

    end
    it "should warn but continue if the file exists but the process name does not" do
      @file.should_receive(:gets).and_return('667')
      ps = stub("ProcTableStruct", :comm => 'test')
      ::Sys::ProcTable.should_receive(:ps).with(667).and_return(nil)
      STDERR.should_receive(:puts).with('WARNING: resetting stale lockfile')
      @file.should_receive(:rewind)
      @file.should_receive(:write).with(666)
      Pidlock.new('my.pid').lock

    end
  end
end
