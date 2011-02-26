%w(curl git-core libreadline5-dev zlib1g-dev libssl-dev libxml2-dev libxslt1-dev ).each do |pkg|
  package pkg
end

log "#{node[:travis][:user]} #{node[:travis][:group]}"

bash "install RVM" do
  environment ({'HOME' => "/home/#{node[:travis][:user]}"})
  user node[:travis][:user]
  group node[:travis][:group]
  cwd "/home/#{node[:travis][:user]}"
  code "bash < <( curl http://rvm.beginrescueend.com/releases/rvm-install-head )"
  not_if { File.exists?("/home/#{node[:travis][:user]}/.rvm/bin/rvm") }
end

bash "installing #{node[:travis][:ruby_version]}" do
  environment ({'HOME' => "/home/#{node[:travis][:user]}"})
  user node[:travis][:user]
  group node[:travis][:group]
  cwd "/home/#{node[:travis][:user]}"
  code <<-EOH
    [[ -s "$HOME/.rvm/scripts/rvm" ]] && . "$HOME/.rvm/scripts/rvm"
    rvm install #{node[:travis][:ruby_version]}
  EOH
  not_if { File.exists?("/home/#{node[:travis][:user]}/.rvm/rubies/ruby-#{node[:travis][:ruby_version]}/bin/ruby") }
end

bash "setting default ruby" do
  environment ({'HOME' => "/home/#{node[:travis][:user]}"})
  user node[:travis][:user]
  group node[:travis][:group]
  cwd "/home/#{node[:travis][:user]}"
  code <<-EOH
    [[ -s "$HOME/.rvm/scripts/rvm" ]] && . "$HOME/.rvm/scripts/rvm"
    rvm --default use #{node[:travis][:ruby_version]}
  EOH
end

template "/home/#{node[:travis][:user]}/.bashrc" do
  source "bashrc.erb"
  owner node[:travis][:user]
  group node[:travis][:group]
  mode 0755
  action :create
end
