source 'https://supermarket.chef.io'

metadata

cookbook 'database',
  git: 'https://github.com/kisoku/database',
  branch: 'master'

cookbook 'poise-proxy',
  git: 'https://github.com/poise/poise-proxy',
  branch: 'master'

group :integration do
  cookbook 'poise-graphite-test', path: 'test/cookbooks/graphite-test'
end
