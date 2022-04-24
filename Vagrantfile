nodes = [
  { :hostname => 'k8s-master',   :role => 'master',  :ip => '192.168.50.10',  :ip2 => '192.168.0.10', :ram => 4096, :box => 'centos/8',  :forPort => 2100, :cidr => '192.168.50.0/24' }, 
  { :hostname => 'k8s-worker01', :role => 'worker',  :ip => '192.168.50.20', :ram => 2048, :box => 'centos/8', :forPort => 2101, :cidr => '192.168.50.0/24' } ,
  { :hostname => 'k8s-worker02', :role => 'worker',  :ip => '192.168.50.30', :ram => 2048, :box => 'centos/8', :forPort => 2102, :cidr => '192.168.50.0/24' }
]

# wireless device
w_dev = 'Qualcomm Atheros QCA9377 Wireless Network Adapter'

# Access
user = "daniel"  # This is not working yet. Default user still vagrant
pass = "test123"

# Enable some features installation during clustering
fea_dash = "Y"
fea_helm = "Y"
fea_met  = "Y"
fea_mlb  = "Y"

Vagrant.configure("2") do |config|
  nodes.each do |node|
    config.vm.define node[:hostname] do |nodeconfig|
	    
      nodeconfig.vm.network "forwarded_port",  guest: 22, host: node[:forPort]  # in case you are in a vpn, you can redirect
      nodeconfig.vm.box = node[:box]  # change name that appear in the virtual box
      nodeconfig.vm.hostname = node[:hostname] 
      # nodeconfig.ssh.username = "#{user}" # The vagrant spin up VM is not working

      nodeconfig.vm.network :private_network, ip: node[:ip]  ## configure network according to variables node
      
      # Public IP for master for remote testing
      if node[:hostname] == 'k8s-master'
        nodeconfig.vm.network :public_network, ip: node[:ip2], bridge: "#{w_dev}", dev: "#{w_dev}"
      end
      
      nodeconfig.vm.provider :virtualbox do |domain|
        domain.memory = node[:ram] 
        domain.cpus = 2 
		    domain.name = node[:hostname] 
      end

      # Provision /etc/hosts file
      nodes.each do |hosts_node|
        nodeconfig.vm.provision :shell, path: "./scripts/set_hosts.sh", :args => [hosts_node[:ip], hosts_node[:hostname]]
      end

      # Configure K8s-Cluster
      nodeconfig.vm.provision "main-scripts", :type => "shell", :path => "scripts/run.sh", privileged: false, :args => "#{node[:ip]} #{node[:cidr]} #{node[:role]} #{pass} #{fea_dash} #{fea_helm} #{fea_met} #{fea_mlb} "  ## Execute base script
  
    end
  end
end

