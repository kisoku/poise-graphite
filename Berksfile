source 'https://api.berkshelf.com'

metadata

cookbook 'qosp_repo',
  git: 'https://github.qualcomm.com/ootcs-chef/qosp_repo-chef',
  branch: 'master'

cookbook 'poise-proxy',
  git: 'https://github.com/poise/poise-proxy',
  branch: 'master'

group :integration do
  cookbook 'graphite-test', path: 'test/cookbooks/graphite-test'
end
