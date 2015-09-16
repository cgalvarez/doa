require 'spec_helper'
describe 'meteor' do

  context 'with defaults for all parameters' do
    it { should contain_class('meteor') }
  end
end
