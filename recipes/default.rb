#
# Cookbook Name::       cloudwatch_monitoring
# Description::         Base configuration for cloudwatch_monitoring
# Recipe::              default
# Author::              Alexis Midon
#
# See https://github.com/alexism/cloudwatch_monitoring
#
# Copyright 2013, Alexis Midon
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

install_path = "#{node[:cw_mon][:home_dir]}/aws-scripts-mon-#{node[:cw_mon][:version]}"
zip_filepath = "#{node[:cw_mon][:home_dir]}/CloudWatchMonitoringScripts-#{node[:cw_mon][:version]}.zip"

%w(unzip libwww-perl libdatetime-perl).each do |p|
  package p do
    action :install
  end
end

group node[:cw_mon][:group] do
  action :create
end

user node[:cw_mon][:user] do
  group node[:cw_mon][:group]
  home node[:cw_mon][:home_dir]
  supports manage_home: true
  action :create
end

remote_file zip_filepath do
  source node[:cw_mon][:release_url]
  owner node[:cw_mon][:user]
  group node[:cw_mon][:group]
  mode 0755
  not_if { File.directory? install_path }
end

bash 'extract_aws-scripts-mon' do
  user node[:cw_mon][:user]
  group node[:cw_mon][:group]
  cwd ::File.dirname(zip_filepath)
  code <<-EOH
    rm -rf #{install_path}
    [[ -d #{File.dirname(install_path)} ]] || mkdir -vp #{File.dirname(install_path)}
    unzip #{zip_filepath}
    mv -v ./aws-scripts-mon #{install_path}
    chown -R #{node[:cw_mon][:user]}:#{node[:cw_mon][:group]} #{install_path}
    rm #{zip_filepath}
  EOH
  not_if { File.directory? install_path }
end

options = %w(--from-cron) + node[:cw_mon][:options]

if iam_role = IAM::role
  log "IAM role available: #{iam_role}"
else
  log "No IAM role available for CloudWatch Monitoring" do
    level :warn
  end

  template "#{install_path}/awscreds.conf" do
    owner node[:cw_mon][:user]
    group node[:cw_mon][:group]
    mode 0600
    source 'awscreds.conf.erb'
    variables cw_mon: node[:cw_mon]
  end

  options << "--aws-credential-file #{install_path}/awscreds.conf"
end

cron 'cloudwatch_monitoring' do
  minute "*/#{node[:cw_mon][:cron_minutes]}"
  user node[:cw_mon][:user]
  command %Q{#{install_path}/mon-put-instance-data.pl #{(options).join(' ')} || logger -t aws-scripts-mon "status=failed exit_code=$?"}
end
