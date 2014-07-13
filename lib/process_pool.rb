# Allows you to spin off a pool of subprocesses that is not larger than X, and
# maintains a pool of those proceses. You can then enqueue tasks to be executed
# within that pool. When all slots are full the caller will be blocked until a slot becomes
# available.
#
#   manager = ProcessPool.new(slots = 4)
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
# If you have a finite Enumerable at hand you can also launch it into the ProcessPool, like so:
#
#  manager = ProcessPool.new(slots = 4)
#  
#  manager.map_fork(job_tickets) do | job_ticket |
#    # this block will run in a forked subprocess
#    Churner.new(job).churn
#    ...
#  end
#
# Can be rewritten using Threads if operation on JVM/Rubinius will be feasible.
class Chantier::ProcessPool
  # Kill the spawned processes after at most X seconds
  KILL_AFTER_SECONDS = 60 * 2
  
  # http://linuxman.wikispaces.com/killing+me+softly
  TERMINATION_SIGNALS = %w( TERM HUP INT QUIT PIPE KILL )
  
  # The manager uses loops in a few places. By doing a little sleep()
  # in those loops we can yield process control back to the OS which brings
  # the CPU usage of the managing process to small numbers. If you just do
  # a loop {} MRI will saturate a whole core and not let go off of it until
  # the loop returns.
  SCHEDULER_SLEEP_SECONDS = 0.05
  
  def initialize(num_procs)
    raise "Need at least 1 slot, given #{num_procs.to_i}" unless num_procs.to_i > 0
    @pids = [nil] * num_procs.to_i
    @semaphore = Mutex.new
  end
  
  # Distributes the elements in the given Enumerable to parallel workers,
  # N workers at a time. The method will return once all the workers for all
  # the elements of the Enumerable have terminated.
  #
  #   pool = ProcessPool.new(5)
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
  
  # Run the given block in a forked subprocess. This method will block
  # the thread it is called from until a slot in the process table
  # becomes free. Once that happens, the given block will be forked off
  # and the method will return.
  def fork_task(&blk)
    destination_slot_idx = nil
    
    # Try to find a slot in the process table where this job can go
    catch :_found do
      loop do
        @semaphore.synchronize do
          if destination_slot_idx = @pids.index(nil)
            @pids[destination_slot_idx] = true # occupy it
            throw :_found
          end
        end
        sleep SCHEDULER_SLEEP_SECONDS # Breathing room
      end
    end
    
    task_pid = fork(&blk)
    
    # No need to lock this because we already reserved that slot
    @pids[destination_slot_idx] = task_pid
    
    puts("Spun off a task process #{task_pid} into slot #{destination_slot_idx}") if $VERBOSE
    
    # Dispatch the watcher thread that will record that the process has quit into the
    # process table
    Thread.new do
      Process.wait(task_pid) # This call will block until that process quites
      # Now we can remove that process from the process table
      @semaphore.synchronize { @pids[destination_slot_idx] = nil }
    end
    
    # Dispatch the killer thread which kicks in after KILL_AFTER_SECONDS.
    # Note that we do not manage the @pids table here because once the process
    # gets terminated it will bounce back to the standard wait() above.
    Thread.new do
      sleep KILL_AFTER_SECONDS
      begin
        TERMINATION_SIGNALS.each do | sig |
          Process.kill(sig, task_pid)
          sleep 5 # Give it some time to react
        end
      rescue Errno::ESRCH
        # It has already quit, nothing to do
      end
    end
  end
  
  # Tells whether some processes are still churning
  def still_running?
    @pids.any?{|e| e }
  end
  
  # Analogous to Process.wait or wait_all - will block until all of the process slots have been freed.
  def block_until_complete!
    loop do
      return unless still_running?
      sleep SCHEDULER_SLEEP_SECONDS # Breathing room
    end
  end
end