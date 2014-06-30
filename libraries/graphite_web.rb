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

require File.expand_path('../graphite', __FILE__)
require File.expand_path('../config_builder', __FILE__)

class Chef
  class Resource::GraphiteWeb < Chef::Resource
    include Poise(Graphite)
    include Poise::Resource::SubResourceContainer
    include ConfigBuilder

    actions(:install, :uninstall, :enable, :disable, :start, :stop, :restart)

    # fetch these from parent
    attribute(:graphite_root, kind_of: String, config_attribute: true, default: lazy { parent.path })
    attribute(:conf_dir, kind_of: String, config_attribute: true, default: lazy { parent.conf_dir })
    attribute(:storage_dir, kind_of: String, config_attribute: true, default: lazy { parent.storage_dir })
    attribute(:content_dir, kind_of: String, config_attribute: true, default: lazy { "#{parent.path}/webapp/content" })
    attribute(:dashboard_conf, kind_of: String, config_attribute: true, default: lazy { "#{parent.conf_dir}/dashboard.conf" })
    attribute(:graphtemplates_conf, kind_of: String, config_attribute: true, default: lazy { "#{parent.conf_dir}/graphTemplates.conf" })
    attribute(:ceres_dir, kind_of: String, config_attribute: true, default: lazy { parent.ceres_dir })
    attribute(:whisper_dir, kind_of: String, config_attribute: true, default: lazy { parent.whisper_dir })
    attribute(:rrd_dir, kind_of: String, config_attribute: true, default: lazy { parent.rrd_dir })
    attribute(:log_dir, kind_of: String, config_attribute: true, default: lazy { parent.log_dir })
    attribute(:index_file, kind_of: String, config_attribute: true)

    attribute(:secret_key, kind_of: String, config_attribute: true)
    attribute(:allowed_hosts, kind_of: Array, default: [ '*' ], config_attribute: true)
    attribute(:documentation_url, kind_of: String, config_attribute: true)
    attribute(:default_cache_duration, kind_of: String, config_attribute: true)
    attribute(:log_rendering_performance, equal_to: [true, false], config_attribute: true)
    attribute(:log_cache_performance, equal_to: [true, false], config_attribute: true)
    attribute(:log_metric_access, equal_to: [true, false], config_attribute: true)
    attribute(:debug, equal_to: [true, false], config_attribute: true)
    attribute(:flushrrdcache, kind_of: String, config_attribute: true)
    attribute(:memcache_hosts, kind_of: String, config_attribute: true)
    attribute(:default_cache_duration, kind_of: String, config_attribute: true)
    attribute(:email_backend, kind_of: String, config_attribute: true)
    attribute(:email_host, kind_of: String, config_attribute: true)
    attribute(:email_port, kind_of: Fixnum, config_attribute: true)
    attribute(:email_host_user, kind_of: String, config_attribute: true)
    attribute(:email_host_password, kind_of: String, config_attribute: true)
    attribute(:email_use_tls, equal_to: [true, false], config_attribute: true)
    attribute(:use_ldap_auth, equal_to: [true, false], config_attribute: true)
    attribute(:ldap_server, kind_of: String, config_attribute: true)
    attribute(:ldap_port, kind_of: Fixnum, config_attribute: true)
    attribute(:ldap_use_tls, equal_to: [true, false], config_attribute: true)
    attribute(:ldap_uri, kind_of: String, config_attribute: true)
    attribute(:ldap_search_base, kind_of: String, config_attribute: true)
    attribute(:ldap_base_user, kind_of: String, config_attribute: true)
    attribute(:ldap_base_pass, kind_of: String, config_attribute: true)
    attribute(:ldap_user_query, kind_of: String, config_attribute: true)
    attribute(:use_remote_user_authentication, equal_to: [true, false], config_attribute: true)
    attribute(:login_url, kind_of: String, config_attribute: true)
    attribute(:dashboard_require_authentication, equal_to: [true, false], config_attribute: true)
    attribute(:dashboard_require_edit_group, kind_of: String, config_attribute: true)
    attribute(:dashboard_require_permissions, equal_to: [true, false], config_attribute: true)
    # attribute(:databases, kind_of: String, config_attribute: true)
    attribute(:cluster_servers, kind_of: Array, config_attribute: true)
    attribute(:remote_find_timeout, kind_of: Float, config_attribute: true)
    attribute(:remote_fetch_timeout, kind_of: Float, config_attribute: true)
    attribute(:remote_retry_delay, kind_of: Float, config_attribute: true)
    attribute(:remote_reader_cache_size_limit, kind_of: Fixnum, config_attribute: true)
    attribute(:find_cache_duration, kind_of: Fixnum, config_attribute: true)
    attribute(:find_tolerance, kind_of: Fixnum, config_attribute: true)
    attribute(:remote_rendering, equal_to: [true, false], config_attribute: true)
    attribute(:rendering_hosts, kind_of: Array, config_attribute: true)
    attribute(:remote_render_connect_timeout, kind_of: Float, config_attribute: true)
    attribute(:carbonlink_hosts, kind_of: Array, config_attribute: true)
    attribute(:carbonlink_timeout, kind_of: Float, config_attribute: true)
    attribute(:carbonlink_retry_delay, kind_of: Fixnum, config_attribute: true)
    attribute(:carbonlink_hashing_keyfunc, kind_of: String, config_attribute: true)
    attribute(:carbon_metric_prefix, kind_of: String, config_attribute: true)
    attribute(:replication_factor, kind_of: Fixnum, config_attribute: true)
    attribute(:max_fetch_retries, kind_of: Fixnum, config_attribute: true)

    attribute(:gunicorn_options, option_collector: true)

    attribute(:enable_proxy, equal_to: [true, false], default: true)
    attribute(:port, kind_of: Fixnum, default: 8000)
    attribute(:local_settings, template: true)

    def provider(arg=nil)
      if arg.kind_of?(String) || arg.kind_of?(Symbol)
        class_name = Mixin::ConvertToClassName.convert_to_class_name(arg.to_s)
        arg = Provider::GraphiteWeb.const_get(class_name) if Provider::GraphiteWeb.const_defined?(class_name)
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
      :gunicorn
    end

    def service_name
      "graphite_web_#{name}"
    end

    def config_key_formatter(key)
      key.upcase
    end

    def config_value_formatter(val)
      python_value_formatter(val)
    end
  end
  class Provider::GraphiteWeb < Chef::Provider
    include Poise(Graphite)

    def action_install
      notifying_block do
        create_local_settings
        # create_database
        install_service
        install_proxy
      end
    end

    def action_uninstall
      action_stop
      unconfigure_service
    end

    def action_enable
      subcontext_block do
        service_resource.run_action(:enable)
      end
    end

    def action_disable
      subcontext_block do
        service_resource.run_action(:start)
      end
    end

    def action_start
      subcontext_block do
        service_resource.run_action(:start)
      end
    end

    def action_stop
      subcontext_block do
        service_resource.run_action(:stop)
      end
    end

    def action_restart
      subcontext_block do
        service_resource.run_action(:restart)
      end
    end

    private

    def create_local_settings
      if !new_resource.local_settings_source && !new_resource.local_settings_content(nil, true)
        new_resource.local_settings_source('local_settings.py.erb')
        new_resource.local_settings_cookbook('graphite')
      end

      file "#{new_resource.parent.path}/webapp/local_settings.py" do
        owner new_resource.parent.user
        group new_resource.parent.group
        mode '0644'
        content new_resource.local_settings_content
      end
    end

    def configure_service
      service_resource
    end

    def unconfigure_service
      raise NotImplementedError
    end

    def service_resource
      include_recipe 'runit'

      @service_resource ||= runit_service new_resource.service_name do
        cookbook 'graphite'
        run_template_name 'graphite_web'
        log_template_name 'graphite_web'
        options(
          service_resource: new_resource
        )
      end
    end

    def install_proxy
      svc = new_resource
      if new_resource.enable_proxy
        poise_proxy "graphite_web_#{new_resource.name}" do
          parent svc
          ssl_enabled true
          ssl_redirect_http true
          provider :nginx
        end
      end
    end
  end

  class Provider::GraphiteWeb::Gunicorn < Chef::Provider::GraphiteWeb
    def install_service
    end
  end
end
