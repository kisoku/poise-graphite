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
  class Resource::Carbon < Chef::Resource
    include Poise(Graphite)
    include ConfigBuilder

    actions(:install, :uninstall, :enabled, :disable, :start, :stop, :restart)

    attribute(:storage_dir, kind_of: String, config_attribute: true)
    attribute(:local_data_dir, kind_of: String, config_attribute: true)
    attribute(:whitelists_dir, kind_of: String, config_attribute: true)
    attribute(:conf_dir, kind_of: String, config_attribute: true)
    attribute(:log_dir, kind_of: String, config_attribute: true)
    attribute(:pid_dir, kind_of: String, config_attribute: true)
    attribute(:user, kind_of: String, config_attribute: true)

    attribute(:line_receiver_interface, kind_of: String, default: '0.0.0.0', config_attribute: true)
    attribute(:line_receiver_port, kind_of: Fixnum, default: 2003, config_attribute: true)
    attribute(:pickle_receiver_interface, kind_of: String, default: '0.0.0.0', config_attribute: true)
    attribute(:pickle_receiver_port, kind_of: Fixnum, default: 2004, config_attribute: true)
    attribute(:enable_udp_listener, equal_to: [ true, false ], default: false, config_attribute: true)
    attribute(:udp_receiver_interface, kind_of: String, default: '0.0.0.0', config_attribute: true)
    attribute(:udp_receiver_port, kind_of: Fixnum, default: 2003, config_attribute: true)
    attribute(:use_insecure_unpickler, equal_to: [ true, false ], default: false, config_attribute: true)

    attribute(:enable_amqp, equal_to: [ true, false ], default: false, config_attribute: true) #false
    attribute(:amqp_verbose, equal_to: [ true, false ], config_attribute: true) # false
    attribute(:amqp_host, kind_of: String, config_attribute: true) # 'localhost'
    attribute(:amqp_port , kind_of: Fixnum, config_attribute: true) # 5672
    attribute(:amqp_vhost, kind_of: String, config_attribute: true) # '/'
    attribute(:amqp_user, kind_of: String, config_attribute: true) # 'guest'
    attribute(:amqp_password, kind_of: String, config_attribute: true) # 'guest'
    attribute(:amqp_exchange, kind_of: String, config_attribute: true) # 'graphite'
    attribute(:amqp_metric_name_in_body, equal_to: [ true, false ], config_attribute: true) # false

    attribute(:max_cache_size, kind_of: String, config_attribute: true)
    attribute(:max_updates_per_second, kind_of: Fixnum, config_attribute: true) # 500 ?
    attribute(:max_updates_per_second_on_shutdown, kind_of: Fixnum, config_attribute: true) # 1000 ?
    attribute(:max_creates_per_minute, kind_of: Fixnum, config_attribute: true) # 50 ?
    attribute(:cache_query_interface, kind_of: String, default: '0.0.0.0', config_attribute: true)
    attribute(:cache_query_port, kind_of: Fixnum, default: 7002, config_attribute: true)
    attribute(:use_flow_control, equal_to: [ true, false ], default: true, config_attribute: true)
    attribute(:log_updates, equal_to: [ true, false ], default: false, config_attribute: true)
    attribute(:log_cache_hits, equal_to: [ true, false ], default: false, config_attribute: true)
    attribute(:whisper_autoflush, equal_to: [ true, false ], default: false, config_attribute: true)
    attribute(:whisper_sparse_create, equal_to: [ true, false ], default: false, config_attribute: true)
    attribute(:whisper_fallocate_create, equal_to: [ true, false ], default: false, config_attribute: true)
    attribute(:whisper_lock_writes, equal_to: [ true, false ], default: false, config_attribute: true)
    attribute(:use_whitelist, equal_to: [ true, false ], default: false, config_attribute: true)
    attribute(:carbon_metric_prefix, kind_of: String, default: 'carbon', config_attribute: true)
    attribute(:carbon_metric_interval, kind_of: Fixnum, default: 60, config_attribute: true)
    attribute(:enable_manhole, equal_to: [ true, false ], default: false, config_attribute: true) # false
    attribute(:manhole_interface, kind_of: String, config_attribute: true) # '127.0.0.1'
    attribute(:manhole_port, kind_of: Fixnum, config_attribute: true) # 7222
    attribute(:manhole_user, kind_of: String, config_attribute: true) # 'admin'
    attribute(:manhole_public_key, kind_of: Fixnum, config_attribute: true)
    attribute(:bind_patterns, kind_of: Fixnum, config_attribute: true)

    def provider(arg=nil)
      if arg.kind_of?(String) || arg.kind_of?(Symbol)
        class_name = Mixin::ConvertToClassName.convert_to_class_name(arg.to_s)
        arg = Provider::Carbon.const_get(class_name) if Provider::Carbon.const_defined?(class_name)
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
      :runit
    end

    def run_template_name
      'carbon'
    end

    def log_template_name
      'carbon'
    end

    def command
      raise NotImplementedError
    end

    def service_name
      raise NotImplementedError
    end

    def config_key_formatter(key)
      key.upcase
    end

    def config_section_name
      raise NotImplementedError
    end

    def local_destinations
      dests = parent.subresources.select {|r| r.is_a?(Chef::Resource::CarbonCache) && r.action != :nothing }
      dests.collect {|d| "#{d.pickle_receiver_interface}:#{d.pickle_receiver_port}:#{d.name}" }
    end
  end

  class Resource::CarbonCache < Chef::Resource::Carbon


    def config_section_name
      "cache:#{name}"
    end

    def service_name
      "carbon_cache_#{name}"
    end

    def command
      "carbon-cache.py"
    end
  end

  class Resource::CarbonRelay < Chef::Resource::Carbon

    attribute(:relay_method, equal_to: [ 'rules', 'consistent-hashing', 'aggregated-consistent-hashing' ], config_attribute: true)
    attribute(:replication_factor, kind_of: Fixnum, config_attribute: true)
    attribute(:destinations, kind_of: Array, default: lazy { local_destinations }, config_attribute: true, config_value_formatter: :array_to_csv)
    attribute(:max_queue_size, kind_of: Fixnum, default: 10000, config_attribute: true)
    attribute(:max_datapoints_per_message, kind_of: Fixnum, default: 500, config_attribute: true)
    attribute(:queue_low_watermark_pct, kind_of: Float, default: 0.8, config_attribute: true)
    attribute(:time_to_defer_sending, kind_of: Float, default: 0.0001, config_attribute: true)
    attribute(:use_flow_control, equal_to: [true, false], default: true, config_attribute: true)

    def config_section_name
      "relay:#{name}"
    end

    def service_name
      "carbon_relay_#{name}"
    end

    def command
      "carbon-relay.py"
    end
  end

  class Resource::CarbonAggregator < Chef::Resource::Carbon

    attribute(:destinations, kind_of: Array, default: lazy { local_destinations }, config_attribute: true, config_value_formatter: :array_to_csv)

    def config_section_name
      "aggregator:#{name}"
    end

    def service_name
      "carbon_aggregator_#{name}"
    end

    def command
      "carbon-aggregator.py"
    end
  end

  class Provider::Carbon < Chef::Provider
    include Poise(Graphite)

    def action_install
      notifying_block do
        configure_service
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

    def configure_service
      service_resource
    end

    def unconfigure_service
      raise NotImplementedError
    end

    def service_resource
      raise NotImplementedError
    end
  end
  class Provider::Carbon::Runit < Chef::Provider::Carbon

    private

    def service_resource
      include_recipe 'runit'

      @service_resource ||= runit_service new_resource.service_name do
        cookbook 'graphite'
        run_template_name new_resource.run_template_name
        log_template_name new_resource.log_template_name
        options(
          service_resource: new_resource
        )
      end
    end
  end
end
