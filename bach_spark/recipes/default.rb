node.default[:bcpc][:hadoop][:yarn][:aux_services][:spark_shuffle][:class] =
  'org.apache.spark.network.yarn.YarnShuffleService'

spark_pkg_version = node[:spark][:package][:version]
spark_bin_dir = node[:spark][:bin][:dir]

if node[:spark][:package][:install_meta] == true
  package 'spark' do
    action :upgrade
  end
else
  package "spark-#{spark_pkg_version}" do
    action :install
  end
end

template "#{spark_bin_dir}/conf/spark-env.sh" do
  source 'spark-env.sh.erb'
  mode 0755
end

template "#{spark_bin_dir}/conf/spark-defaults.conf" do
  source 'spark-defaults.conf.erb'
  mode 0755
end

link "/#{spark_bin_dir}/lib/spark-yarn-shuffle.jar" do
  to "#{spark_bin_dir}/lib/spark-#{spark_pkg_version}-yarn-shuffle.jar"
end

link '/usr/spark/current' do
  to "#{spark_bin_dir}"
end

# install fortran libs needed by some jobs
package 'libatlas3gf-base' do
  action :install
end

package 'libopenblas-base' do
  action :install
end
