require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Chantier::ProcessPoolWithKill do
  
  before(:each) do
    @files = (0...20).map do
      SecureRandom.hex(12).tap { |filename| FileUtils.touch(filename) }
    end
  end
  
  after(:each) do
    @files.map(&File.method(:unlink))
  end
  
  context '#map_fork' do
    let(:manager) { described_class.new(5) }
    
    it 'processes multiple files' do
      
      data_chunks = (0..10).map{|e| Digest::SHA1.hexdigest(e.to_s) }
      
      expect(manager).not_to be_still_running
      
      manager.map_fork(@files) do | filename |
        sleep(0.05 + (rand / 10))
        File.open(filename, "wb"){|f| f.write("Worker completed for #{filename}") }
      end
      
      expect(manager).not_to be_still_running
      
      @files.each do | filename |
        expect(File.read(filename)).to eq("Worker completed for #{filename}")
      end
    end
  end
  
  context 'with 0 concurrent slots' do
    it 'raises an exception' do
      expect {
        described_class.new(0)
      }.to raise_error(RuntimeError, 'Need at least 1 slot, given 0')
      
      expect {
        described_class.new(-1)
      }.to raise_error(RuntimeError, 'Need at least 1 slot, given -1')
    end
  end
  
  context 'with 1 slot' do
    let(:manager) { described_class.new(1) }
    
    it 'processes 1 file' do
      filename = @files[0]
      pid = manager.fork_task do
        sleep(0.05 + (rand / 10))
        File.open(filename, "wb"){|f| f.write("Worker completed") }
      end
      
      expect(pid).to be_kind_of(Fixnum)
      
      manager.block_until_complete!
      
      expect(File.read(filename)).to eq('Worker completed')
    end
    
    it 'processes multiple files' do
      expect(manager).not_to be_still_running
      
      @files.each do | filename |
        manager.fork_task do
          sleep(0.05 + (rand / 10))
          File.open(filename, "wb"){|f| f.write("Worker completed for #{filename}") }
        end
      end
      
      expect(manager).to be_still_running
      
      manager.block_until_complete!
      
      @files.each do | filename |
        expect(File.read(filename)).to eq("Worker completed for #{filename}")
      end
    end
    
    it 'forcibly quites a process that is hung for too long' do
      manager_with_short_timeout = described_class.new(1, kill_after_seconds: 0.4)
      
      filename = SecureRandom.hex(22)
      manager_with_short_timeout.fork_task do
        10.times do
          sleep 1 # WAY longer than the timeout
        end
        File.open(filename, "wb") {|f| f.write("Should never happen")}
      end
      
      manager_with_short_timeout.block_until_complete!
      expect(File.exist?(filename)).to eq(false)
    end
  end
  
  context 'with failures' do
    class AlwaysWrong
      def arm!; end
      def limit_reached?; true; end
    end
    
    it 'honors the failure policy object passed in' do
      subject = described_class.new(5, failure_policy: AlwaysWrong.new)
      expect {
        subject.fork_task { "never happens" }
      }.to raise_error("Reached error limit of processes quitting with non-0 status")
    end
  end
  
  context 'with 5 slots' do
    let(:manager) { described_class.new(5) }
    
    it 'processes multiple files' do
      
      expect(manager).not_to be_still_running
      
      @files.each do | filename |
        manager.fork_task do
          sleep(0.05 + (rand / 10))
          File.open(filename, "wb"){|f| f.write("Worker completed for #{filename}") }
        end
      end
      
      expect(manager).to be_still_running
      
      manager.block_until_complete!
      
      @files.each do | filename |
        expect(File.read(filename)).to eq("Worker completed for #{filename}")
      end
    end
  end
end

