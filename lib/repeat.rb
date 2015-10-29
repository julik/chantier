module Chantier::Repeat
  def fork_task_in_all_slots(&blk)
    loop { fork_task(&blk) }
  end
end
