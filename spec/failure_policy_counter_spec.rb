require_relative 'spec_helper'

describe Chantier::FailurePolicies::Count do
  it 'performs the counts with the right responses' do
    policy = described_class.new(12)
    
    policy.arm!
    
    (644 - 12).times { policy.success! }
    expect(policy).not_to be_limit_reached
    
    5.times { policy.failure! }
    expect(policy).not_to be_limit_reached
    
    (12 - 5).times { policy.failure! }
    expect(policy).to be_limit_reached
  end
  
  it 'resets the counts when calling arm!' do
    policy = described_class.new(4)
    policy.arm!
    4.times { policy.failure! }
    expect(policy).to be_limit_reached
    
    policy.arm!
    expect(policy).not_to be_limit_reached
  end
end