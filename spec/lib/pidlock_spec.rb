require 'spec_helper'

describe Pidlock do
  before(:each) do
    @file = stub(File)
    @file.stub(:flock)
    @file.stub(:write)
    @file.stub(:flock => 0)
    @file.stub(:flush)
    @file.stub(:gets)
    File.should_receive(:open).with('/var/run/x/my.pid', 'w+').and_return(@file)
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

    it "should use /tmp if /var/run is not writeable"
    it "should warn but start the process if the file exists but the process name does not match the pid"
  end
end
