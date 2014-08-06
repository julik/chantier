require_relative 'spec_helper'

describe Chantier::FailurePolicies::Percentage do
  it 'performs the percentage checks' do
    policy = described_class.new(40.0)
    policy.arm!
    
    599.times { policy.success! }
    1.times { policy.failure! }
    expect(policy).not_to be_limit_reached
    
    399.times { policy.failure! }
    expect(policy).to be_limit_reached
  end
  
  it 'resets the counts when calling arm!' do
    policy = described_class.new(40)
    policy.arm!
    
    50.times { policy.failure! }
    50.times { policy.success! }
    expect(policy).to be_limit_reached
    
    policy.arm!
    expect(policy).not_to be_limit_reached
  end
end
