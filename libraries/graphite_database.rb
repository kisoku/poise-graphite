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

require_relative 'graphite_web'
require_relative 'config_builder'

class Chef
  class Resource::GraphiteDatabase < Chef::Resource
    include Poise(parent: :graphite_web)
    include ConfigBuilder

    provides(:graphite_database)

    actions(:install, :uninstall)

    attribute(:name, kind_of: String, default: 'graphite', name_attribute: true, config_attribute: true)
    attribute(:user, kind_of: String, default: 'graphite', config_attribute: true)
    attribute(:password, kind_of: String, config_attribute: true)
    attribute(:engine, kind_of: String, default: 'django.db.backends.postgresql_psycopg2', config_attribute: true)
    attribute(:host, kind_of: String, default: '127.0.0.1', config_attribute: true)
    attribute(:port, kind_of: Fixnum, default: 5432, config_attribute: true)
    attribute(:options, option_collector: true, config_attribute: true)
    attribute(:admin_user, kind_of: String)
    attribute(:admin_password, kind_of: String)

    def provider(arg=nil)
      if arg.kind_of?(String) || arg.kind_of?(Symbol)
        class_name = Mixin::ConvertToClassName.convert_to_class_name(arg.to_s)
        arg = Provider::GraphiteDatabase.const_get(class_name) if Provider::GraphiteDatabase.const_defined?(class_name)
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
      :postgresql
    end

    def config_value_formatter_name(val)
      "#{val.split('::').last}"
    end

    def config_key_formatter(key)
      key.upcase
    end

    def config_value_formatter(val)
      python_value_formatter(val)
    end

    def to_conf
      buf = String.new
      h = { default: {}}

      self.class.config_attributes.each do |attr|
        line = format_attribute(attr, "%s,%s")
        if line
          k,v = line.split(',')
          # XXX stupid hack, find something better
          v.gsub!(/'/, '') if v.is_a? String
          h[:default][k] = v
        end
      end

      buf << "DATABASES = %s" % JSON.pretty_generate(h)
    end
  end

  class Provider::GraphiteDatabase < Chef::Provider
    include Poise(parent: :graphite_web)

    def action_install
      raise NotImplementedError
    end

    def action_uninstall
      raise NotImplementedError
    end
  end

  class Provider::GraphiteDatabase::Postgresql < Chef::Provider::GraphiteDatabase
    def action_install
      include_recipe 'postgresql::ruby'

      notifying_block do
        create_user
        create_database
        sync_database
      end
    end

    private

    def db_connection
      @db_connection ||= {
        host: new_resource.host,
        port: new_resource.port,
        username: new_resource.admin_user,
        password: new_resource.admin_password
      }
    end


    def create_user
      conn = db_connection
      postgresql_database_user new_resource.user do
        connection conn
        password new_resource.password
      end
    end

    def create_database
      conn = db_connection
      # XXX don't like this hack either
      postgresql_database new_resource.name.split('::').last do
        connection conn
        owner new_resource.user
      end
    end

    def sync_database
      execute "initialize database for #{new_resource.name}" do
        command "su -l -c '#{new_resource.parent.parent.bin_dir}/django-admin.py syncdb --noinput --settings=graphite.settings' - graphite"
      end
    end
  end
end
