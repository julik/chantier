# Allows you to spin off a pool of subprocesses that is not larger than X, and
# maintains a pool of those proceses (same as ProcessPool). Will also forcibly quit
# those processes after a certain period to ensure they do not hang
#
#   manager = ProcessPoolWithKill.new(slots = 4, kill_after = 5) # seconds
#   jobs_hose.each_job do | job |
#     # this call will block until a slot becomes available
#     manager.fork_task do # this block runs in a subprocess
#       Churner.new(job).churn
#     end
#     manager.still_running? # => most likely "true"
#   end
#   
#   manager.block_until_complete! #=> Will block until all the subprocesses have terminated
class Chantier::ProcessPoolWithKill < Chantier::ProcessPool
  
  # http://linuxman.wikispaces.com/killing+me+softly
  TERMINATION_SIGNALS = %w( TERM HUP INT QUIT PIPE KILL )
  
  DEFAULT_KILL_TIMEOUT = 60
  def initialize(num_procs, kill_after_seconds = DEFAULT_KILL_TIMEOUT)
    @kill_after_seconds = kill_after_seconds.to_f
    super(num_procs)
  end
  
  # Run the given block in a forked subprocess. This method will block
  # the thread it is called from until a slot in the process table
  # becomes free. Once that happens, the given block will be forked off
  # and the method will return.
  def fork_task(&blk)
    task_pid = super
    Thread.abort_on_exception = true
    # Dispatch the killer thread which kicks in after KILL_AFTER_SECONDS.
    # Note that we do not manage the @pids table here because once the process
    # gets terminated it will bounce back to the standard wait() above.
    Thread.new do
      sleep @kill_after_seconds
      TERMINATION_SIGNALS.each do | sig |
        begin
          Process.kill(sig, task_pid)
          sleep 1 # Give it some time to react
        rescue Errno::ESRCH
          # It has already quit, nothing to do
        end
      end
    end
    
    return task_pid
  end
  
end