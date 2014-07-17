require 'spec_helper'

describe 'graphite' do
  describe user('graphite') do
    it { should exist }
  end

  describe group('graphite') do
    it { should exist }
  end

  describe file('/opt/graphite') do
    it { should be_directory }
    it { should be_owned_by 'graphite' }
    it { should be_grouped_into 'graphite' }
  end

  describe command('/opt/graphite/bin/pip list') do
    its (:stdout) { should match /carbon/ }
    its (:stdout) { should match /carbonate/ }
    its (:stdout) { should match /ceres/ }
    its (:stdout) { should match /graphite-web/ }
    its (:stdout) { should match /whisper/ }
  end

  describe file('/opt/graphite/conf/aggregation-rules.conf') do
    it { should be_file }
  end

  describe file('/opt/graphite/conf/carbon.conf') do
    it { should be_file }
  end

  describe file('/opt/graphite/conf/relay-rules.conf') do
    it { should be_file }
  end

  describe file('/opt/graphite/conf/storage-aggregation.conf') do
    it { should be_file }
  end

  describe file('/opt/graphite/conf/storage-schemas.conf') do
    it { should be_file }
  end
end
