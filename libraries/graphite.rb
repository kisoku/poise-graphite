#
# Cookbook Name:: poise-graphite
#
# Copyright 2014, Mathieu Sauve-Frankel
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

class Chef
  class Resource::Graphite < Chef::Resource
    include Poise
    include Poise::Resource::SubResourceContainer

    actions(:install, :uninstall, :nothing)

    attribute(:path, kind_of: String, default: '/opt/graphite', name_attribute: true)
    attribute(:user, kind_of: String, default: 'graphite')
    attribute(:uid, kind_of: Fixnum)
    attribute(:group, kind_of: String, default: 'graphite')
    attribute(:gid, kind_of: Fixnum)
    attribute(:bin_dir, kind_of: String, default: lazy { "#{path}/bin" })
    attribute(:conf_dir, kind_of: String, default: lazy { "#{path}/conf" })
    attribute(:local_data_dir, kind_of: String, default: lazy { "#{storage_dir}/whisper" })
    attribute(:log_dir, kind_of: String, default: lazy { "#{storage_dir}/log" })
    attribute(:storage_dir, kind_of: String, default: lazy { "#{path}/storage" })
    attribute(:whisper_dir, kind_of: String, default: lazy { "#{storage_dir}/whisper" })
    attribute(:ceres_dir, kind_of: String, default: lazy { "#{storage_dir}/ceres" })
    attribute(:rrd_dir, kind_of: String, default: lazy { "#{storage_dir}/rrd" })

    attribute(:aggregation_rules, template: true)
    attribute(:carbon_conf, template: true)
    attribute(:storage_schemas, template: true)
    attribute(:storage_aggregation, template: true)
    attribute(:relay_rules, template: true)

    def provider(arg=nil)
      if arg.kind_of?(String) || arg.kind_of?(Symbol)
        class_name = Mixin::ConvertToClassName.convert_to_class_name(arg.to_s)
        arg = Provider::Graphite.const_get(class_name) if Provider::Graphite.const_defined?(class_name)
      end
      super(arg)
    end

    def provider_for_action(*args)
      unless provider
        provider(self.class.default_provider)
      end
      super
    end

    def self.default_provider
      :virtualenv
    end

    def carbon_services
      subresources.select { |r| r.is_a?(Chef::Resource::Carbon) && r.action != :nothing }
    end

    def carbon_caches
      subresources.select { |r| r.is_a?(Chef::Resource::CarbonCache) && r.action != :nothing }
    end

    def carbon_relays
      subresources.select { |r| r.is_a?(Chef::Resource::CarbonRelay) && r.action != :nothing }
    end

    def carbon_aggregators
      subresources.select { |r| r.is_a?(Chef::Resource::CarbonAggregator) && r.action != :nothing }
    end
  end
  class Provider::Graphite < Chef::Provider
    include Poise

    def action_install
      notifying_block do
        create_group
        create_user
        install_graphite
        create_aggregation_rules
        create_carbon_conf
        create_storage_schemas_conf
        create_storage_aggregation_conf
        create_relay_rules
      end
    end

    def action_uninstall
      notifying_block do
        uninstall_graphite
      end
    end

    private

    def create_group
      group new_resource.group do
        gid new_resource.gid if new_resource.gid
      end
    end

    def create_user
      user new_resource.user do
        gid new_resource.group
        uid new_resource.uid if new_resource.uid
        home new_resource.path
        supports({:manage_home => true})
        system true
        shell '/bin/bash'
      end
    end

    def create_aggregation_rules
      if !new_resource.aggregation_rules_source && !new_resource.aggregation_rules_content(nil, true)
        new_resource.aggregation_rules_source('aggregation-rules.conf.erb')
        new_resource.aggregation_rules_cookbook('graphite')
      end

      file "#{new_resource.conf_dir}/aggregation-rules.conf" do
        owner new_resource.user
        group new_resource.group
        mode '0644'
        content new_resource.aggregation_rules_content
        new_resource.carbon_aggregators.each  do |res|
          notifies :restart, res
        end
      end
    end

    def create_carbon_conf
      if !new_resource.carbon_conf_source && !new_resource.carbon_conf_content(nil, true)
        new_resource.carbon_conf_source('carbon.conf.erb')
        new_resource.carbon_conf_cookbook('graphite')
      end

      file "#{new_resource.conf_dir}/carbon.conf" do
        owner new_resource.user
        group new_resource.group
        mode '0644'
        content new_resource.carbon_conf_content
        new_resource.carbon_services.each  do |res|
          notifies :restart, res
        end
      end
    end

    def create_storage_schemas_conf
      if !new_resource.storage_schemas_source && !new_resource.storage_schemas_content(nil, true)
        new_resource.storage_schemas_source('storage-schemas.conf.erb')
        new_resource.storage_schemas_cookbook('graphite')
      end

      file "#{new_resource.conf_dir}/storage-schemas.conf" do
        owner new_resource.user
        group new_resource.group
        mode '0644'
        content new_resource.storage_schemas_content
        new_resource.carbon_caches.each  do |res|
          notifies :restart, res
        end
      end
    end

    def create_storage_aggregation_conf
      if !new_resource.storage_aggregation_source && !new_resource.storage_aggregation_content(nil, true)
        new_resource.storage_aggregation_source('storage-aggregation.conf.erb')
        new_resource.storage_aggregation_cookbook('graphite')
      end

      file "#{new_resource.conf_dir}/storage-aggregation.conf" do
        owner new_resource.user
        group new_resource.group
        mode '0644'
        content new_resource.storage_aggregation_content
        new_resource.carbon_aggregators.each  do |res|
          notifies :restart, res
        end
      end
    end

    def create_relay_rules
      if !new_resource.relay_rules_source && !new_resource.relay_rules_content(nil, true)
        new_resource.relay_rules_source('relay-rules.conf.erb')
        new_resource.relay_rules_cookbook('graphite')
      end

      file "#{new_resource.conf_dir}/relay-rules.conf" do
        owner new_resource.user
        group new_resource.group
        mode '0644'
        content new_resource.relay_rules_content
        new_resource.carbon_relays.each  do |res|
          notifies :restart, res
        end
      end
    end

    def create_whitelist
    end

    def create_blacklist
    end

    def install_graphite
      raise NotImplementedError
    end

    def uninstall_graphite
      raise NotImplementedError
    end
  end

  class Provider::Graphite::Package < Chef::Provider::Graphite
    # XXX This provider currently depends on a home rolled graphite package
    # which I am waiting for permission to open source
    # I am working on a virtualenv-based provider

    private

    def install_graphite
      package 'graphite'
    end

    def uninstall_graphite
      package 'graphite' do
        action :remove
      end
    end
  end

  class Provider::Graphite::Virtualenv < Chef::Provider::Graphite

    private

    def package_dependencies
      %w[
        libffi-dev
        libyaml-0-2
        libyaml-dev
        libcairo2
        libcairo2-dev
        libldap-2.4.2
        libldap2-dev
        libsasl2-2
        libsasl2-dev
      ]
    end

    def install_graphite
      install_dependencies
      create_virtualenv
      install_eggs
    end

    private

    def install_dependencies
      include_recipe 'build-essential'
      include_recipe 'git'
      include_recipe 'python'
      include_recipe 'postgresql::client'

      package_dependencies.each {|p| package p }
    end



    def create_virtualenv
      python_virtualenv new_resource.path do
        owner new_resource.user
        group new_resource.group
      end
    end

    def install_eggs
      python_pip 'psycopg2' do
        user new_resource.user
        group new_resource.group
        virtualenv new_resource.path
      end

      python_pip 'Twisted' do
        user new_resource.user
        group new_resource.group
        virtualenv new_resource.path
      end

      python_pip 'txamqp' do
        user new_resource.user
        group new_resource.group
        virtualenv new_resource.path
      end

      python_pip 'git+https://github.com/graphite-project/carbon#egg=carbon' do
        user new_resource.user
        group new_resource.group
        options "--install-option='--install-lib=#{new_resource.path}/lib/python2.7/site-packages'"
        virtualenv new_resource.path
      end

      python_pip 'git+https://github.com/graphite-project/ceres.git#egg=ceres' do
        user new_resource.user
        group new_resource.group
        virtualenv new_resource.path
      end

      python_pip 'git+https://github.com/graphite-project/whisper.git#egg=whisper' do
        user new_resource.user
        group new_resource.group
        virtualenv new_resource.path
      end

      python_pip 'git+https://github.com/jssjr/carbonate.git#egg=carbonate' do
        user new_resource.user
        group new_resource.group
        virtualenv new_resource.path
      end

      python_pip 'Django' do
        user new_resource.user
        group new_resource.group
        virtualenv new_resource.path
      end

      python_pip 'python-memcached' do
        version '1.47'
        user new_resource.user
        group new_resource.group
        virtualenv new_resource.path
      end

      python_pip 'simplejson' do
        version '2.1.6'
        user new_resource.user
        group new_resource.group
        virtualenv new_resource.path
      end

      python_pip 'django-tagging' do
        version '0.3.1'
        user new_resource.user
        group new_resource.group
        virtualenv new_resource.path
      end

      python_pip 'gunicorn' do
        user new_resource.user
        group new_resource.group
        virtualenv new_resource.path
      end

      python_pip 'pytz' do
        user new_resource.user
        group new_resource.group
        virtualenv new_resource.path
      end

      python_pip 'pyparsing' do
        user new_resource.user
        group new_resource.group
        virtualenv new_resource.path
      end

      python_pip 'python-ldap' do
        user new_resource.user
        group new_resource.group
        virtualenv new_resource.path
      end

      python_pip 'http://cairographics.org/releases/py2cairo-1.8.10.tar.gz#egg=pycairo' do
        user new_resource.user
        group new_resource.group
        virtualenv new_resource.path
      end

      python_pip 'git+https://github.com/graphite-project/graphite-web#egg=graphite-web' do
        user new_resource.user
        group new_resource.group
        options "--install-option='--install-lib=#{new_resource.path}/lib/python2.7/site-packages'"
        virtualenv new_resource.path
      end
    end
  end
end
