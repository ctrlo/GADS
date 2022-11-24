# -*- mode: ruby -*-
# vi: set ft=ruby :

#
# Setup:
# 1) Configure config.yml
#    - plugins/DBIC/default
# 2) $ vagrant up
# 3) Place a database dump in the app root (as database.sql)
# 4) $ vagrant provision --provision-with db
# 5) $ vagrant up
# 6) $ vagrant ssh
#      > cd /vagrant
#      > DBIC_MIGRATION_USERNAME=postgres DBIC_MIGRATION_PASSWORD=test123 dbic-migration upgrade -Ilib --schema_class='GADS::Schema' --dsn='dbi:Pg:database=gads;host=127.0.0.1'
# 7) Logon onto the PostgreSQL webinterface, login, navigate to the user table inside
#    the gads database. Edit a user so it now has your email address. After that you
#    can go ahead and reset your password.
#

#
# Run
# 1) $ vagrant up
# 2) Open http://192.168.33.10:3000
#

#
# Debug app / view console:
# $ vagrant ssh
#   > screen -r
#

#
# VM user
#   username:   vagrant
#   password:   vagrant
#
# App
#   URL:        http://192.168.33.10/phppgadmin/
#
# PostgreSQL:
#   username:   postgres
#   password:   test123
#   phpPgAdmin: http://192.168.33.10/phppgadmin/
#


# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.
Vagrant.configure("2") do |config|
  # The most common configuration options are documented and commented below.
  # For a complete reference, please see the online documentation at
  # https://docs.vagrantup.com.

  # Every Vagrant development environment requires a box. You can search for
  # boxes at https://vagrantcloud.com/search.
  config.vm.box = "bento/ubuntu-17.10"

  # Disable automatic box update checking. If you disable this, then
  # boxes will only be checked for updates when the user runs
  # `vagrant box outdated`. This is not recommended.
  # config.vm.box_check_update = false

  # Create a forwarded port mapping which allows access to a specific port
  # within the machine from a port on the host machine. In the example below,
  # accessing "localhost:8080" will access port 80 on the guest machine.
  # NOTE: This will enable public access to the opened port
  # config.vm.network "forwarded_port", guest: 80, host: 8080

  # Create a forwarded port mapping which allows access to a specific port
  # within the machine from a port on the host machine and only allow access
  # via 127.0.0.1 to disable public access
  # config.vm.network "forwarded_port", guest: 80, host: 8080, host_ip: "127.0.0.1"

  # Create a private network, which allows host-only access to the machine
  # using a specific IP.
  config.vm.network "private_network", ip: "192.168.33.10"

  # Create a public network, which generally matched to bridged network.
  # Bridged networks make the machine appear as another physical device on
  # your network.
  # config.vm.network "public_network"

  # Share an additional folder to the guest VM. The first argument is
  # the path on the host to the actual folder. The second argument is
  # the path on the guest to mount the folder. And the optional third
  # argument is a set of non-required options.
  config.vm.synced_folder "./", "/vagrant", mount_options: ['dmode=777', 'fmode=777']

  # Provider-specific configuration so you can fine-tune various
  # backing providers for Vagrant. These expose provider-specific options.
  # Example for VirtualBox:
  #
  config.vm.provider "virtualbox" do |vb|
    # Display the VirtualBox GUI when booting the machine
    vb.gui = true

    # Customize the amount of memory on the VM:
    vb.memory = "1024"

    vb.cpus = 2
    vb.name = "ctrlo"
  end
  #
  # View the documentation for the provider you are using for more
  # information on available options.

  # Enable provisioning with a shell script. Additional provisioners such as
  # Puppet, Chef, Ansible, Salt, and Docker are also available. Please see the
  # documentation for more information about their specific syntax and use.
  config.vm.provision "setup", type: "shell", inline: <<-SHELL
    apt-get update
    apt-get install -y libxi-dev libxmu-dev freeglut3-dev libgsl0-dev libnetpbm10-dev libplplot-dev pgplot5 build-essential gfortran
    apt-get install -y libyaml-perl libdatetime-perl libdbix-class-helpers-perl libdancer2-perl libdatetime-format-sqlite-perl libdatetime-format-strptime-perl
    apt-get install -y  libinline-perl liblua5.1-0-dev liblua50-dev liblualib50-dev libdbd-pg-perl

    curl -L http://cpanmin.us | perl - --sudo App::cpanminus
    (cd /vagrant && perl bin/output_cpanfile > cpanfile)
    cpanm --installdeps /vagrant

    apt -y install postgresql postgresql-contrib phppgadmin
    sudo -u postgres psql -c "ALTER USER postgres WITH PASSWORD 'test123';"
    sed -i 's/Require local/Require all granted/' /etc/apache2/conf-available/phppgadmin.conf
    sed -i "s/extra_login_security'\] = true/extra_login_security'\] = false/" /etc/phppgadmin/config.inc.php
    systemctl restart postgresql
    systemctl restart apache2

    debconf-set-selections <<< "postfix postfix/mailname string ctrlo.digitpaint.nl"
    debconf-set-selections <<< "postfix postfix/main_mailer_type string 'Internet Site'"
    apt-get install -y postfix
  SHELL

  config.vm.provision "db", type: "shell", run: "never", inline: <<-SHELL
    sudo -u postgres psql -c "DROP DATABASE gads;"
    sudo -u postgres psql -c "CREATE DATABASE gads;"
    sudo -u postgres psql gads < /vagrant/database.sql
  SHELL

  config.vm.provision "server", type: "shell", run: "always", inline: <<-SHELL
    cd /vagrant
    sudo -u vagrant screen -d -m perl ./bin/app.pl
  SHELL
end
