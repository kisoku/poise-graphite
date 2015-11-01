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

require_relative 'graphite'
require_relative 'config_builder'

class Chef
  class Resource::GraphiteStorageSchemaRule < Chef::Resource
    include Poise(parent: :graphite)
    include ConfigBuilder

    provides(:graphite_storage_schema_rule)

    actions(:nothing)

    attribute(:pattern, kind_of: String, required: true, config_attribute: true )
    attribute(:retentions, kind_of: [ String, Array ], required: true, config_attribute: true, config_value_formatter: :array_to_csv)
  end

  class Provider::GraphiteStorageSchemaRule < Chef::Provider
    include Poise(parent: :graphite)
  end
end
