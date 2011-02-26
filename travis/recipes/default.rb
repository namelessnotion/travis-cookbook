include_recipe "redis"
include_recipe "postgresql::server"
include_recipe "postgresql::client"

repository_uri = node[:travis][:repository]
deploy_to_path = node[:travis][:deploy_to] 
user_name = node[:travis][:user]
group_name = node[:travis][:group]

group group_name do
  action :create
end

user user_name do
  action :create
  gid group_name
  home "/home/#{user_name}"
  shell "/bin/bash"
  manage_home true
  action :create
end

include_recipe "travis::rvm"

package "git-core" do
  action :install
end

%w{rake bundler}.each do |gem_name|
  bash "installing gem #{gem_name}" do
    environment ({'HOME' => "/home/#{user_name}"})
    user user_name
    group group_name
    cwd "/home/#{user_name}"
    code <<-EOH
      [[ -s "$HOME/.rvm/scripts/rvm" ]] && . "$HOME/.rvm/scripts/rvm"
      gem install #{gem_name} --no-ri --no-rdoc
    EOH
  end
end

directory deploy_to_path do
  owner user_name
  group group_name
  mode '0755'
  recursive true
  action :create
end

directory "#{deploy_to_path}/shared" do
  owner user_name
  group group_name
  mode '0755'
  recursive true
  action :create
end

%w{ log pids system vendor_bundle }.each do |dir|
  directory "#{deploy_to_path}/shared/#{dir}" do
    owner user_name
    group group_name
    mode '0755'
    recursive true
    action :create
  end
end

#
# deploy travis and setup database
#

deploy "travis" do
  deploy_to deploy_to_path
  repository repository_uri
  revision "HEAD"
  user user_name
  group group_name
  migrate false #this is really true since we migrate in the before migrate
  # migration shell command doesn't work since rvm isn't loaded
  # migration_command <<-EOH
    # [[ -s "$HOME/.rvm/scripts/rvm" ]] && . "$HOME/.rvm/scripts/rvm"
    # rake db:setup
    # rake db:schema:load
  # EOH
  environment "RAILS_ENV" => "production"
  action :force_deploy

  before_migrate do

    if node[:travis][:run_rails_app]
      bash "insert postgresql into gemfile" do
        user user_name
        group group_name
        cwd release_path
        code <<-EOH
          echo "gem 'pg'" >> #{release_path}/Gemfile
        EOH
      end
    end

    bash "running bundler" do
      environment ({'HOME' => "/home/#{user_name}", "RAILS_ENV" => "production"})
      user user_name
      group group_name
      cwd release_path
      #bundle deployment didn't work because of the pg gem
      code <<-EOH
        [[ -s "$HOME/.rvm/scripts/rvm" ]] && . "$HOME/.rvm/scripts/rvm"
        bundle install --without development test cucumber
      EOH
    end

    #
    # database configuraiton
    #

    template "#{release_path}/config/database.yml" do
      source "database.yml.erb"
      owner user_name
      group group_name
      mode "644"
      variables(
        :host => node['fqdn'],
        :databases => node[:travis][:databases]
      )
    end

    bash "setup db and load schema" do
      environment ({'HOME' => "/home/#{user_name}", 'RAILS_ENV' => "production"})
      user user_name
      group group_name
      cwd release_path
      code <<-EOH
        [[ -s "$HOME/.rvm/scripts/rvm" ]] && . "$HOME/.rvm/scripts/rvm"
        rake db:setup
        rake db:schema:load
      EOH
    end
  end
end
