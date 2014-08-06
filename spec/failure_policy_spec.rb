require_relative 'spec_helper'

describe Chantier::FailurePolicies::None do
  it 'has all the necessary methods' do
    expect(subject.arm!).to be_nil
    expect(subject.failure!).to be_nil
    expect(subject.success!).to be_nil
    expect(subject.limit_reached?).to be_nil
  end
end