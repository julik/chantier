require_relative 'spec_helper'

def rsleep
  sleep(rand(10)/1200.0)
end

describe Chantier::FailurePolicies::MutexWrapper do
  class NonThreadsafe
    attr_reader :arms, :successes, :failures, :limits_reached
    
    def initialize
      @arms, @successes, @failures, @limits_reached = 0,0,0,0
    end
    
    def arm!
      @arms += 6
      rsleep
      @arms -= 6
      rsleep
      @arms += 1
    end
    
    def success!
      @successes += 12
      rsleep
      @successes -= 12
      rsleep
      @successes += 1
    end
    
    def failure!
      @failures += 4
      rsleep
      @failures -= 4
      rsleep
      @failures += 1
    end
    
    def limit_reached?
      @limits_reached += 13
      rsleep
      @limits_reached -= 13
      rsleep
      @limits_reached += 1
    end
  end
  
  it 'evaluates a non-threadsafe object in this spec' do
    policy = NonThreadsafe.new
    
    n = 400
    states = []
    threads = (1..n).map do | n |
      Thread.new do
        rsleep
        policy.arm!
        rsleep
        policy.failure!
        rsleep
        policy.success!
        rsleep
        policy.limit_reached?
        call_counts = [
          policy.arms,
          policy.failures,
          policy.successes,
          policy.limits_reached,
        ]
        states << call_counts
      end
    end
    
    threads.map(&:join)
    expect(states.uniq.length).not_to eq(n)
  end
  
  it 'wraps all the necessary methods' do
    wrapped = NonThreadsafe.new
    policy = described_class.new(wrapped)
    
    n = 400
    states = []
    threads = (1..n).map do | n |
      Thread.new do
        rsleep
        policy.arm!
        rsleep
        policy.failure!
        rsleep
        policy.success!
        rsleep
        policy.limit_reached?
        call_counts = [
          wrapped.arms,
          wrapped.failures,
          wrapped.successes,
          wrapped.limits_reached,
        ]
        states << call_counts
      end
    end
    
    threads.map(&:join)
    expect(states.uniq.length).to eq(n)
  end
end
