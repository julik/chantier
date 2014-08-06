module Chantier::FailurePolicies
  # A very basic failure policy that will do nothing at all.
  # It will always answer "nil" to limit_reached?, therefore allowing
  # the works to proceed indefinitely. By overriding the four main methods
  # on it you can control the policy further.
  #
  # Note that all calls to arm!, failure!, success! and limit_reached? are
  # automatically protected by a Mutex - you don't need to set one up
  # yourself.
  class None
    # Start counting the failures (will be triggered on the first job). You can manually
    # call this to reset the object the object to the initial state (reset error counts)
    def arm!
    end
  
    # Increment the failure counter
    def failure!
    end
  
    # Increment the success counter
    def success!
    end
  
    # Tells whether the failure policy has been triggered.
    # Return something falsey from here if everything is in order
    def limit_reached?
    end
  end

  # Simplest failure policy based on overall error count.
  #
  #   policy = FailAfterCount.new(4)
  #   policy.limit_reached? # => false
  #   1.times { policy.failure! }
  #   policy.limit_reached? # => false
  #   #... and then
  #   4.times { policy.failure! }
  #   policy.limit_reached? # => true
  class Count < None
    def initialize(max_failures)
      @max = max_failures
    end
  
    # Arm the counter, prepare all the parameters
    def arm!
      @count = 0
    end
  
    # Register a failure (simply increments the counter)
    def failure!
      @count += 1
    end
  
    # Tells whether we had too many failures
    def limit_reached?
      @count >= @max
    end
  end

  # Limits the number of failures that may be registered 
  # by percentage of errors vs successful triggers.
  #
  #   policy = FailByPercentage.new(40)
  #   policy.limit_reached? # => false
  #   600.times { policy.success! }
  #   policy.limit_reached? # => false
  #   1.times { policy.failure! }
  #   policy.limit_reached? # => false
  #   400.times { policy.failure! }
  #   policy.limit_reached? # => true
  class Percentage < None
    def initialize(percents_failing)
      @threshold = percents_failing
    end
    
    def arm!
      @failures, @successes = 0, 0
    end
    
    def failure!
      @failures += 1
    end
  
    def success!
      @successes += 1
    end
  
    def limit_reached?
      ratio = @failures.to_f / (@failures + @successes)
      (ratio * 100) >= @threshold
    end
  end

  # Limits the number of failures that may be registered
  # within the given interval
  #
  #   policy = FailWithinTimePeriod.new(4, 60 * 2)
  #   policy.limit_reached? # => false
  #   #... and then during 1 minute
  #   5.times { policy.failure! }
  #   policy.limit_reached? # => true
  #
  # Once the interval is passed, the error count will
  # be reset back to 0.
  class WithinInterval < None
    def initialize(max_per_interval, interval_in_seconds)
      @max = max_per_interval
      @interval = interval_in_seconds
    end
    
    def arm!
      @interval_started = Time.now.utc.to_f
      @count = 0
    end
  
    def failure!
      t = Time.now.utc.to_f
      if (t - @interval_started) > @interval
        @interval_started = t
        @count = 0
      end
      @count += 1
    end
  
    def limit_reached?
      @count >= @max
    end
  end

  # Wraps a FailurePolicy-compatible object in a Mutex 
  # for all method calls.
  class MutexWrapper
    def initialize(failure_policy)
      @policy = failure_policy
      @mutex = Mutex.new
    end
  
    def arm!
      @mutex.synchronize { @policy.arm! }
    end
  
    def success!
      @mutex.synchronize { @policy.success! }
    end
  
    def failure!
      @mutex.synchronize { @policy.failure! }
    end
  
    def limit_reached?
      @mutex.synchronize { @policy.limit_reached? }
    end
  end
end
