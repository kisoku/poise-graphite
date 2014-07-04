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
    attribute(:group, kind_of: String, default: 'graphite')
    attribute(:bin_dir, kind_of: String, default: lazy { "#{path}/bin" })
    attribute(:conf_dir, kind_of: String, default: lazy { "#{path}/conf" })
    attribute(:local_data_dir, kind_of: String, default: lazy { "#{storage_dir}/whisper" })
    attribute(:log_dir, kind_of: String, default: lazy { "#{storage_dir}/log" })
    attribute(:storage_dir, kind_of: String, default: lazy { "#{path}/storage" })
    attribute(:whisper_dir, kind_of: String, default: lazy { "#{storage_dir}/whisper" })
    attribute(:ceres_dir, kind_of: String, default: lazy { "#{storage_dir}/ceres" })
    attribute(:rrd_dir, kind_of: String, default: lazy { "#{storage_dir}/rrd" })

    attribute(:carbon_conf, template: true)
    attribute(:storage_schemas, template: true)
    attribute(:storage_aggregation, template: true)

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
      :package
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
        create_carbon_conf
        create_storage_schemas_conf
        create_storage_aggregation_conf
      end
    end

    def action_uninstall
      notifying_block do
        uninstall_graphite
      end
    end

    private

    def create_group
      group 'graphite'
    end

    def create_user
      user 'graphite' do
        gid 'graphite'
        system true
        home new_resource.path
        shell '/bin/bash'
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
end
