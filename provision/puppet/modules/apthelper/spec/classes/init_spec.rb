require 'spec_helper'
describe 'apthelper' do

  context 'with defaults for all parameters' do
    it { should contain_class('apthelper') }
  end
end
