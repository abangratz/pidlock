require 'spec_helper'

describe "Pidlock", :filesystem => true do
  let(:logger) { mock(Logger) }

  context "filesystem testing" do
    before(:each) do
      Logger.stub!(:new => logger)

      path = Pathname(File.writable?('/var/run') ? '/var/run' : '/tmp')
      @pid_name = 'my.pid'
      @pid_file = path + @pid_name
      File.unlink(@pid_file) if @pid_file.exist?

      Process.stub(:pid).and_return(666)
      logger.stub!(:warn)
    end

    after(:each) do
      File.unlink(@pid_file) if @pid_file.exist?
    end

    it "enters the correct PID in the pidfile" do

      Pidlock.new(@pid_name).lock
      @pid_file.should exist

      File.read(@pid_file).should eq('666')
    end

    it "cleans up the PID in the pidfile" do

      pidlock = Pidlock.new(@pid_name)
      pidlock.lock
      @pid_file.should exist

      File.read(@pid_file).should eq('666')
      pidlock.unlock

      @pid_file.should_not exist
    end

    it "enters the correct PID in the pidfile when the pidfile is stale" do
      # start with a stale PID in the file
      open(@pid_file, "w") {|f| f.write('1111') }
      File.read(@pid_file).should eq('1111')
      ::Sys::ProcTable.should_receive(:ps).with(1111).and_return(nil)
      logger.should_receive(:warn).with('WARNING: resetting stale lockfile')

      Pidlock.new(@pid_name).lock
      @pid_file.should exist

      File.read(@pid_file).should eq('666')
    end

    it "enters the correct PID in the pidfile when the pid matches a different process" do
      # start with a stale PID in the file
      open(@pid_file, "w") {|f| f.write('1111') }
      File.read(@pid_file).should eq('1111')
      ps = stub("ProcTableStruct", :comm => 'other')
      ::Sys::ProcTable.should_receive(:ps).with(1111).and_return(ps)

      Pidlock.new(@pid_name).lock
      @pid_file.should exist

      File.read(@pid_file).should eq('666')
    end

  end

end
