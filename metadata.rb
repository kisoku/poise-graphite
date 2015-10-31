name 'poise-graphite'
maintainer 'Mathieu Sauve-Frankel'
maintainer_email 'msf@kisoku.net'
license 'Apache 2.0'
description 'Installs/Configures poise-graphite'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version '2.0.1'

depends 'build-essential'
depends 'database'
depends 'git'
depends 'nginx'
depends 'python'
depends 'poise', '~> 2.4'
depends 'runit'
