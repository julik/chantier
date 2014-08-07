require_relative 'spec_helper'

describe Chantier::FailurePolicies::WithinInterval do
  let(:counter) { Chantier::FailurePolicies::Count.new(10) }
  
  it 'does not cross the limit when errors are spread out' do
    policy = described_class.new(counter, 0.5)
    policy.arm!
    
    10.times do
      policy.failure!
      sleep 0.1
    end
    expect(policy).not_to be_limit_reached
  end
  
  it 'does cross the limit when errors are spread out' do
    policy = described_class.new(counter, 0.5)
    policy.arm!
    
    10.times do
      policy.failure!
      sleep 0.01
    end
    expect(policy).to be_limit_reached
    
    policy.arm!
    expect(policy).not_to be_limit_reached
  end
end
