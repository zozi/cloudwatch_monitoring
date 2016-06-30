default[:cw_mon][:user]              = "cloudwatch"
default[:cw_mon][:group]             = "cloudwatch"
default[:cw_mon][:home_dir]          = "/home/#{node[:cw_mon][:user]}"
default[:cw_mon][:version]           = "1.2.0"
default[:cw_mon][:release_url]       = "http://aws-cloudwatch.s3.amazonaws.com/downloads/CloudWatchMonitoringScripts-#{node[:cw_mon][:version]}.zip"

default[:cw_mon][:access_key_id]     = nil
default[:cw_mon][:secret_access_key] = nil

default[:cw_mon][:options] = %w{--disk-path=/ --disk-space-util --disk-space-used --disk-space-avail
                                --swap-util --swap-used
                                --mem-util --mem-used --mem-avail}

default[:cw_mon][:cron_minutes] = 5
