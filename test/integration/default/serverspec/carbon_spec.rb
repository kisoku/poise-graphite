require 'spec_helper'

describe 'carbon_cache' do

  %w[ a b ].each do |name|
    describe command("sv status /etc/sv/carbon_cache_#{name}") do
      it { should return_stdout /run: \/etc\/sv\/carbon_cache_#{name}: \(pid \d+\) \d+s/ }
    end
  end

  # XXX lame limitation of serverspec means we can't test that both of our
  # instances are running here
  describe process('carbon-cache.py') do
    it { should be_running }
  end

  # XXX add .on('127.0.0.1') when serverspec 2 is released
  %w[ 2010 2011 2012 2013 7012 7013 ].each do |i|
    describe port(i) do
      it { should be_listening.with('tcp') }
    end
  end
end

describe 'carbon_relay' do
  describe command('sv status /etc/sv/carbon_relay_a') do
    it { should return_stdout /run: \/etc\/sv\/carbon_relay_a: \(pid \d+\) \d+s/ }
  end

  describe process('carbon-relay.py') do
    it { should be_running }
  end

  %w[ 2003 2004 ].each do |i|
    describe port(i) do
      it { should be_listening.with('tcp') }
    end
  end
end
