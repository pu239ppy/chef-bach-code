package "xfsprogs" do
  action :install
end

directory "/disk" do
  owner "root"
  group "root"
  mode 00755
  action :create
end

if node[:bcpc][:hadoop][:disks].length > 0 then
  node[:bcpc][:hadoop][:disks].each_index do |i|
    directory "/disk/#{i}" do
      owner "root"
      group "root"
      mode 00755
      action :create
      recursive true
    end
   
    d = node[:bcpc][:hadoop][:disks][i]
    execute "mkfs -t xfs -f /dev/#{d}" do
      not_if "file -s /dev/#{d} | grep -q 'SGI XFS filesystem'"
    end
 
    mount "/disk/#{i}" do
      device "/dev/#{d}"
      fstype "xfs"
      options "noatime,nodiratime,inode64"
      action [:enable, :mount]
    end
  end
  if node.roles.include? "BCPC-Hadoop-Head" and node[:bcpc][:hadoop][:head_disks] != nil then
    mnt_idxs = node[:bcpc][:hadoop][:head_disks].map do |dsk| 
      node[:bcpc][:hadoop][:disks].index(dsk)
    end
    if mnt_idxs.include?(nil) then
      Chef::Application.fatal!('node[:bcpc][:hadoop][:head_disks] specifies a disk not found in node[:bcpc][:hadoop][:disks]!')
    end
    node.set[:bcpc][:hadoop][:mounts] = mnt_idxs
  else 
    node.set[:bcpc][:hadoop][:mounts] = (0..node[:bcpc][:hadoop][:disks].length-1).to_a
  end
else
  Chef::Application.fatal!('Please specify some node[:bcpc][:hadoop][:disks]!')
end
