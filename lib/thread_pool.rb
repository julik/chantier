# Allows you to spin off a pool of Threads that is not larger than X. 
# You can then enqueue tasks to be executed within that pool. 
# When all slots are full the caller will be blocked until a slot becomes
# available.
#
#   manager = ThreadPool.new(slots = 4)
#   jobs_hose.each_job do | job |
#     # this call will block until a slot becomes available
#     manager.fork_task do # this block runs in a subprocess
#       Churner.new(job).churn
#     end
#     manager.still_running? # => most likely "true"
#   end
#   
#   manager.block_until_complete! #=> Will block until all the subprocesses have terminated
#
# If you have a finite Enumerable at hand you can also launch it into the ThreadPool, like so:
#
#  manager = ThreadPool.new(slots = 4)
#  
#  manager.map_fork(job_tickets) do | job_ticket |
#    # this block will run in a forked subprocess
#    Churner.new(job).churn
#    ...
#  end
#
# Can be rewritten using Threads if operation on JVM/Rubinius will be feasible.
class Chantier::ThreadPool
  include Chantier::Repeat
  
  # The manager uses loops in a few places. By doing a little sleep()
  # in those loops we can yield process control back to the OS which brings
  # the CPU usage of the managing process to small numbers. If you just do
  # a loop {} MRI will saturate a whole core and not let go off of it until
  # the loop returns.
  SCHEDULER_SLEEP_SECONDS = (1.0 / 500)
  
  # Initializes a new ProcessPool with the given number of workers. If max_failures is
  # given the fork_task method will raise an exception if more than N threads spawned
  # have raised during execution.
  def initialize(num_threads, failure_policy: Chantier::FailurePolicies::None.new)
    raise "Need at least 1 slot, given #{num_threads.to_i}" unless num_threads.to_i > 0
    @threads = [nil] * num_threads.to_i
    @semaphore = Mutex.new
    
    @failure_policy = Chantier::FailurePolicies::MutexWrapper.new(failure_policy)
    @failure_policy.arm!
    
    # Information on the last exception that happened
    @last_representative_exception = nil
  end
  
  # Distributes the elements in the given Enumerable to parallel workers,
  # N workers at a time. The method will return once all the workers for all
  # the elements of the Enumerable have terminated.
  #
  #   pool = ThreadPool.new(5)
  #   pool.map_fork(array_of_urls) do | single_url |
  #     Faraday.get(single_url).response ...
  #     ...
  #     ...
  #   end
  def map_fork(arguments_per_job, &blk)
    arguments_per_job.each do | single_block_argument |
      fork_task { yield(single_block_argument) }
    end
    block_until_complete!
  end
  
  # Run the given block in a thread. This method will block
  # the thread it is called from until a slot in the thread table
  # becomes free.
  def fork_task(&blk)
    if @failure_policy.limit_reached?
      raise @last_representative_exception
    end
    
    destination_slot_idx = nil
    
    # Try to find a slot in the process table where this job can go
    catch :_found do
      loop do
        @semaphore.synchronize do
          if destination_slot_idx = @threads.index(nil)
            @threads[destination_slot_idx] = true # occupy it
            throw :_found
          end
        end
        sleep SCHEDULER_SLEEP_SECONDS # Breathing room
      end
    end
    
    # No need to lock this because we already reserved that slot
    @threads[destination_slot_idx] = Thread.new do
      # Run the given block
      run_block_with_exception_protection(&blk)
      # ...and remove that process from the process table
      @semaphore.synchronize { @threads[destination_slot_idx] = nil }
    end
  end
  
  # Tells whether some processes are still churning
  def still_running?
    @threads.any?{|e| e && e.respond_to?(:alive?) && e.alive? }
  end
  
  # Analogous to Process.wait or wait_all - will block until all of the 
  # threads have terminated
  def block_until_complete!
    @threads.map do |e| 
      if e.respond_to?(:join) && e.alive?
        e.join
      end
    end
  end
  
  private
  
  def run_block_with_exception_protection(&blk)
    yield
    @failure_policy.success!
  rescue Exception => e
    # Register the failure and decrement the counter. If we had more than N 
    # failures stop the machine completely by raising an exception in the caller.
    @failure_policy.failure!
    @last_representative_exception = e if @failure_policy.limit_reached?
  end
  
end