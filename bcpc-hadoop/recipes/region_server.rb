include_recipe 'bcpc-hadoop::hbase_config'
::Chef::Recipe.send(:include, Bcpc_Hadoop::Helper)
::Chef::Resource::Bash.send(:include, Bcpc_Hadoop::Helper)

node.default['bcpc']['hadoop']['copylog']['region_server'] = {
    'logfile' => "/var/log/hbase/hbase-hbase-0-regionserver-#{node.hostname}.log", 
    'docopy' => true
}

node.default['bcpc']['hadoop']['copylog']['region_server_out'] = {
    'logfile' => "/var/log/hbase/hbase-hbase-0-regionserver-#{node.hostname}.out", 
    'docopy' => true
}

(%w{libsnappy1} +
 %w{hbase hbase-regionserver phoenix}.map{|p| hwx_pkg_str(p, node[:bcpc][:hadoop][:distribution][:release])}).each do |pkg|
  package pkg do
    action :upgrade
  end
end

%w{hbase-client hbase-regionserver phoenix-client}.each do |pkg|
  hdp_select(pkg, node[:bcpc][:hadoop][:distribution][:active_release])
end

user_ulimit "hbase" do
  filehandle_limit 32769
end

directory "/usr/hdp/#{node[:bcpc][:hadoop][:distribution][:active_release]}/hbase/lib/native/Linux-amd64-64" do
  recursive true
  action :create
end

link "/usr/hdp/#{node[:bcpc][:hadoop][:distribution][:active_release]}/hbase/lib/native/Linux-amd64-64/libsnappy.so" do
  to "/usr/lib/libsnappy.so.1"
end

template "/etc/default/hbase" do
  source "hdp_hbase.default.erb"
  mode 0655
  variables(:hbrs_jmx_port => node[:bcpc][:hadoop][:hbase_rs][:jmx][:port])
end

#link "/etc/init.d/hbase-regionserver" do
#  to "/usr/hdp/#{node[:bcpc][:hadoop][:distribution][:release]}/hbase/etc/init.d/hbase-regionserver"
#  notifies :run, 'bash[kill hbase-regionserver]', :immediate
#end
#
#bash "kill hbase-regionserver" do
#  code "pkill -u hbase -f regionserver"
#  action :nothing
#  returns [0, 1]
#end

template "/etc/init.d/hbase-regionserver" do
  source "hdp_hbase-regionserver-initd.erb"
  mode 0655
end

service "hbase-regionserver" do
  supports :status => true, :restart => true, :reload => false
  action [:enable, :start]
  subscribes :restart, "template[/etc/hbase/conf/hadoop-metrics2-hbase.properties]", :delayed
  subscribes :restart, "template[/etc/hbase/conf/hbase-site.xml]", :delayed
  subscribes :restart, "template[/etc/hbase/conf/hbase-policy.xml]", :delayed
  subscribes :restart, "template[/etc/hbase/conf/hbase-env.sh]", :delayed
  subscribes :restart, "template[/etc/hadoop/conf/log4j.properties]", :delayed
  subscribes :restart, "template[/etc/hadoop/conf/hdfs-site.xml]", :delayed
  subscribes :restart, "template[/etc/hadoop/conf/core-site.xml]", :delayed
  subscribes :restart, "bash[hdp-select hbase-regionserver]", :delayed
  subscribes :restart, "user_ulimit[hbase]", :delayed
end
