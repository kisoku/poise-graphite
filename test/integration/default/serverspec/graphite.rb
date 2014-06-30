require 'spec_helper'

describe 'graphite' do
  describe package('graphite') do
    it { should be_installed }
  end
end
