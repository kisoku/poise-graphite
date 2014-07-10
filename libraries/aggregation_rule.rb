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

class Chef
  class Resource::GraphiteAggregationRule < Chef::Resource
    include Poise(Graphite)
    include ConfigBuilder

    actions(:nothing)

    attribute(:output_template, kind_of: String, required: true, config_attribute: true)
    attribute(:frequency, kind_of: Fixnum, required: true, config_attribute: true)
    attribute(:method, kind_of: String, required: true, config_attribute: true)
    attribute(:input_pattern, kind_of: String, required: true, config_attribute: true)

    def to_conf
      "#{output_template} (#{frequency}) = #{method} #{input_pattern}"
    end
  end

  class Provider::GraphiteAggregationRule < Chef::Provider
    include Poise(Graphite)
  end
end
