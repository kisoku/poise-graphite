require 'spec_helper'

describe 'graphite_web' do
  
  describe file('/opt/graphite/webapp/local_settings.py') do
    it { should be_file }
    it { should be_owned_by 'graphite' }
    it { should be_grouped_into 'graphite' }
    it { should be_mode 644 }
  end

  describe command('sv status /etc/sv/graphite_web_gunicorn') do
    it { should return_stdout /run: \/etc\/sv\/graphite_web_gunicorn: \(pid \d+\) \d+s/ }
  end

  describe process('gunicorn') do
    it { should be_running }
  end

  describe port(8000) do
    it { should be_listening.with('tcp') }
  end
end
