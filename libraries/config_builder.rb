#
# Cookbook Name:: poise-graphite
#
# Copyright 2014, Noah Kantrowitz
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

module ConfigBuilder
  module ClassMethods

    def attribute(name, options={})
      is_config_attr = options.delete(:config_attribute)
      if is_config_attr
        self.config_attributes << name
      end

      key_formatter = options.delete(:config_key_formatter)
      if key_formatter
        fail ArgumentError, "config_key_formatter must be a Symbol" unless key_formatter.is_a?(Symbol)
        define_method("config_key_formatter_#{name}") do
          self.send(key_formatter, name)
        end
      end

      val_formatter = options.delete(:config_value_formatter)
      if val_formatter
        fail ArgumentError, "config_value_formatter must be a Symbol" unless val_formatter.is_a?(Symbol)
        define_method("config_value_formatter_#{name}") do |val|
          self.send(val_formatter, val)
        end
      end

      super
    end

    # thanks noah for helping me figure this out
    def config_attributes
      @config_attributes ||= if superclass.respond_to?('config_attributes')
        superclass.config_attributes.dup
      else
        []
      end
    end

    def included(klass)
      super
      klass.extend ClassMethods
    end
  end

  extend ClassMethods

  def format_attribute(attr, format="%s = %s\n")
    if self.respond_to?(:"config_key_formatter_#{attr}")
      key = send(:"config_key_formatter_#{attr}", attr)
    elsif self.respond_to?(:config_key_formatter)
      key = send(:config_key_formatter, attr)
    else
      key = attr
    end

    val = send(attr)
    if val.respond_to?(:empty?) and val.empty?
      nil
    elsif val
      if self.respond_to?(:"config_value_formatter_#{attr}")
        val = send(:"config_value_formatter_#{attr}", val)
      elsif self.respond_to?(:config_value_formatter)
        val = send(:config_value_formatter, val)
      end
      format % [key, val]
    else
      nil
    end
  end

  def to_ini
    buf = String.new
    if self.respond_to?(:config_section_name)
      buf << "[#{config_section_name}]\n"
    else
      buf << "[#{name}]\n"
    end
    buf << to_conf
    buf
  end


  def to_conf
    buf = String.new

    self.class.config_attributes.each do |attr|
      line = format_attribute(attr)
      buf << line if line
    end
    buf
  end

  def array_to_csv(val)
    case val
    when String
      val
    when Array
      val.join(', ')
    else
      raise ArgumentError, 'array_to_csv expects either a String or an Array'
    end
  end

  def python_value_formatter(val, depth=0)
    case val
    when Array
      JSON.pretty_generate(val)
    when String
      "'#{val}'"
    when Fixnum
      val
    when Float
      val
    when TrueClass
      'True'
    when FalseClass
      'False'
    when Hash
      h = {}
      val.each {|k,v| h[k] = python_value_formatter(v, depth.next)}
      if depth == 0
        JSON.pretty_generate(h)
      else
        h
      end
    end
  end
end
