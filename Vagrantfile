# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  # ============================================================================
  # Base Box Configuration
  # ============================================================================
  config.vm.box = "ubuntu/focal64"
  config.vm.box_version = ">= 20220101.0.0"

  # ============================================================================
  # VM Resource Configuration
  # ============================================================================
  config.vm.provider "virtualbox" do |vb|
    # Display the VirtualBox GUI when booting the machine
    vb.gui = false
    
    # Customize the amount of memory on the VM (in megabytes)
    vb.memory = 2048
    
    # Customize CPU count
    vb.cpus = 2
    
    # VM name
    vb.name = "escolasapp-dev"
    
    # Performance tweaks
    vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
    vb.customize ["modifyvm", :id, "--natdnsproxy1", "on"]
    vb.customize ["modifyvm", :id, "--nested-hw-virt", "on"]
    vb.customize ["modifyvm", :id, "--paravirt-provider", "kvm"]
  end

  # ============================================================================
  # Hostname and Network Configuration
  # ============================================================================
  config.vm.hostname = "escolasapp-dev"
  
  # Create a private network, which allows host-only access to the machine
  # using a specific IP.
  config.vm.network "private_network", ip: "192.168.33.10"

  # ============================================================================
  # Port Forwarding
  # ============================================================================
  # Forward application port
  config.vm.network "forwarded_port", guest: 3002, host: 3002, auto_correct: true
  
  # Forward MongoDB port (optional, for local cli access)
  config.vm.network "forwarded_port", guest: 27017, host: 27017, auto_correct: true
  
  # Forward Node debugger port
  config.vm.network "forwarded_port", guest: 9229, host: 9229, auto_correct: true

  # ============================================================================
  # Synced Folders
  # ============================================================================
  # Sync project directory to VM
  config.vm.synced_folder ".", "/home/vagrant/escolasapp",
    owner: "vagrant",
    group: "vagrant",
    mount_options: ["dmode=755,fmode=644"]

  # ============================================================================
  # Provisioning
  # ============================================================================
  # Bootstrap shell provisioner - install basic requirements
  config.vm.provision "shell", path: "vagrant/bootstrap.sh"

  # Ansible provisioner - provision Docker and app
  config.vm.provision "ansible_local" do |ansible|
    ansible.playbook = "ansible/playbooks/vagrant_provision.yml"
    ansible.inventory_path = "ansible/inventories/development/hosts"
    ansible.verbose = false
    ansible.limit = "local"
    # Uncomment for verbose Ansible output:
    # ansible.verbose = "vvv"
  end

  # ============================================================================
  # SSH Configuration
  # ============================================================================
  config.ssh.forward_agent = true
  config.ssh.insert_key = true

  # ============================================================================
  # Message
  # ============================================================================
  config.vm.post_up_message = "
  ╔════════════════════════════════════════════════════════════════╗
  ║                 EscolasApp Development VM Ready               ║
  ╚════════════════════════════════════════════════════════════════╝
  
  Access the VM:
    vagrant ssh
  
  Start the application (inside VM):
    cd /home/vagrant/escolasapp
    docker-compose up -d
  
  Application URLs:
    Web: http://localhost:3002
    API: http://localhost:3002/school (example)
    MongoDB: localhost:27017 (if exposed)
  
  View logs:
    docker-compose logs -f app
  
  Access MongoDB:
    docker exec -it escolasapp_mongodb_1 mongo
  
  Useful commands:
    vagrant suspend  - Pause VM (saves state)
    vagrant resume   - Resume VM
    vagrant destroy  - Delete VM
    vagrant ssh      - SSH into VM
  
  For more info, see INFRASTRUCTURE.md
  "
end
