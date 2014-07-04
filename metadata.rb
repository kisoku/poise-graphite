name 'graphite'
maintainer 'Mathieu Sauve-Frankel'
maintainer_email 'msf@kisoku.net'
license 'Apache 2.0'
description 'Installs/Configures poise-graphite'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version '2.0.0'

depends 'database'
depends 'nginx'
depends 'poise'
depends 'poise-proxy'
depends 'runit'
