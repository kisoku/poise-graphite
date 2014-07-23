#
# Cookbook Name:: graphite-test
# Recipe:: default
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

graphite '/opt/graphite' do
  action :install
end

graphite_storage_schema_rule 'carbon' do
  pattern '^carbon\.'
  retentions '60:90d'
end

graphite_storage_schema_rule 'default_1min_for_1day' do
  pattern '.*'
  retentions '60s:1d'
end

graphite_storage_aggregation_rule 'min' do
  pattern '\.lower$'
  x_files_factor 0.1 
  aggregation_method 'min'
end

carbon_cache 'a' do
  line_receiver_interface '127.0.0.1'
  line_receiver_port 2010
  pickle_receiver_interface '127.0.0.1'
  pickle_receiver_port 2011
  cache_query_interface '127.0.0.1'
  cache_query_port 7012
end

carbon_cache 'b' do
  line_receiver_interface '127.0.0.1'
  line_receiver_port 2012
  pickle_receiver_interface '127.0.0.1'
  pickle_receiver_port 2013
  cache_query_interface '127.0.0.1'
  cache_query_port 7013
end

carbon_relay 'a' do
  line_receiver_interface '0.0.0.0'
  line_receiver_port 2003
  pickle_receiver_interface '0.0.0.0'
  pickle_receiver_port 2004
  relay_method 'consistent-hashing'
end

graphite_web 'gunicorn' do
  carbonlink_hosts lazy {
    parent.carbon_caches.collect {|r| "#{r.cache_query_interface}:#{r.cache_query_port}" }
  }

  database 'graphite' do
    user 'graphite'
    password 'badpassword'
    admin_user 'postgres'
    admin_password node['postgresql']['password']['postgres']
  end

  ldap_options do
    opt_x_tls_require_cert 'ldap.OPT_X_TLS_ALLOW'
  end
end
