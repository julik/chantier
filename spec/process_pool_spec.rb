require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Chantier::ProcessPool do
  
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
        Chantier::ProcessPool.new(0)
      }.to raise_error(RuntimeError, 'Need at least 1 slot, given 0')
      
      expect {
        Chantier::ProcessPool.new(-1)
      }.to raise_error(RuntimeError, 'Need at least 1 slot, given -1')
    end
  end
  
  it 'gets instantiated with the given number of slots' do
    Chantier::ProcessPool.new(10)
  end
  
  context 'with failures' do
    it 'raises after 4 failures' do
      fp = Chantier::FailurePolicies::Count.new(4)
      under_test = described_class.new(num_workers = 3, failure_policy: fp)
      expect {
        15.times do 
          under_test.fork_task { raise "I am such a failure" }
        end
      }.to raise_error('Reached error limit of processes quitting with non-0 status')
    end
    
    it 'runs through the jobs if max_failures is not given' do
      under_test = described_class.new(num_workers=3)
      7.times {
        under_test.fork_task { raise "I am such a failure" }
      }
      under_test.block_until_complete!
      expect(true).to eq(true), "Should have gotten to this assertion without the Pool blocking"
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

