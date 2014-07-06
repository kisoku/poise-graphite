source 'https://api.berkshelf.com'

metadata

cookbook 'database',
  git: 'https://github.com/kisoku/database',
  branch: 'master'

cookbook 'poise-proxy',
  git: 'https://github.com/poise/poise-proxy',
  branch: 'master'

group :integration do
  cookbook 'graphite-test', path: 'test/cookbooks/graphite-test'
end
