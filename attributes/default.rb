require 'securerandom'

default['graphite']['web']['secret_key'] = SecureRandom.hex(48)
