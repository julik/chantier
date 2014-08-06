# chantier

Dead-simple task manager for "fire and forget" jobs. Has two interchangeable pools -
processes and threads. The API of those two is the same, so you can play at will and figure
out which one works better.

The only thing Chantier checks for is that the spun off tasks have completed. It also
limits the number of tasks active at the same time. Your code will block until a slot
becomes available for a task.

    manager = Chantier::ProcessPool.new(slots = 4) # You can also use ThreadPool
    jobs_hose.each_job do | job |
      manager.fork_task do # this call will block until a slot becomes available
        Churner.new(job).churn # this block runs in a subprocess
      end
      manager.still_running? # => most likely "true"
    end
    
    manager.block_until_complete! #=> Will block until all the subprocesses have terminated

If you have a finite `Enumerable` at hand you can also launch it into the 
`ProcessPool`/`ThreadPool`, like so:
 
    manager = Chantier::ThreadPool.new(slots = 4)
    
    manager.map_fork(job_tickets) do | job_ticket | # job_tickets has to be an Enumerable 
      # this block will run in a thread
      Churner.new(job_ticket).churn
      ...
    end

Chantier does not provide any built-in IPC or inter-thread communication features - this
should stimulate you to write your tasks without them having to do IPC in the first place.


## Managing job failure

Chantier implements what it calls `FailurePolicies`. A `Policy` is an object that works
like a counter for failed and successfully completed jobs. After each job, the policy
object will be asked whether `limit_reached?` is now true. If it is, calls to `fork_task()`
on the `Pool` using the failure policy will fail with an exception. There is a number of
standard `FailurePolcies` which can be applied to each specific `Pool`, by supplying it in
the `failure_policy` keyword argument.

For example, to stop the `Pool` from accepting jobs if more than half of the jobs fail
(either by raising an exception within their threads or by exiting the forked process with
a non-0 exit code):

    fp = Chantier::FailurePolicies::Percentage.new(50)
    pool = Chantier::ThreadPool.new(num_threads = 5, failure_policy: fp)
    4.times { pool.fork { puts "All is well"} }
    6.times { pool.fork { raise "Drat!"} } # Will only run 4 times and fail after

To allow only a specific number of failures within a time period:

    fp = Chantier::FailurePolicies::WithinInterval.new(max_failures=5, within_seconds=3)
  
You can use those to set fine-grained failure conditions based on the runtime behavior of
the Pool you are using and job duration/failure rate. Chantier pools are made to run in
very long loops, sometimes indefinitely - so a `FailurePolicy` can be your best friend. You
can also bundle those policies together.


## Contributing to chantier
 
* Check out the latest master to make sure the feature hasn't been implemented or the bug hasn't been fixed yet.
* Check out the issue tracker to make sure someone already hasn't requested it and/or contributed it.
* Fork the project.
* Start a feature/bugfix branch.
* Commit and push until you are happy with your contribution.
* Make sure to add tests for it. This is important so I don't break it in a future version unintentionally.
* Please try not to mess with the Rakefile, version, or history. If you want to have your own version, or is otherwise necessary, that is fine, but please isolate to its own commit so I can cherry-pick around it.

## Copyright

Copyright (c) 2014 Julik Tarkhanov. See LICENSE.txt for
further details.

