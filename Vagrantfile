# -*- mode: ruby -*-
# vi: set ft=ruby :
#
# Telefónica Digital - Product Development and Innovation
#
# THIS CODE AND INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND,
# EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE.
#
# Copyright (c) Telefónica Investigación y Desarrollo S.A.U.
# All rights reserved.
#

Vagrant.configure("2") do |config|

  config.vm.box = "CentOS-6.4-x86_64-v20130427"
  config.vm.box_url = "http://cosmos10.hi.inet:8080/vagrant-boxes/CentOS-6.4-x86_64-v20130427.box"
  config.vm.hostname = "linux"
  $repo_path = "/etc/yum.repos.d/EPEL-Repo-PDI.repo"
  $script = <<SCRIPT
  echo installing EPEL-PDI repo
  echo [EPEL-Repo-PDI] > #$repo_path
  echo name=PDI EPEL Repository >> #$repo_path
  echo baseurl=http://repos.hi.inet/centos/epel6-x86_64/RPMS.all/ >> #$repo_path
  echo enabled=1 >> #$repo_path
  echo gpgcheck=0 >> #$repo_path
  echo installing npm, vim and java
  yum install -y npm vim wget java-1.7.0-openjdk java-1.7.0-openjdk-devel
  echo installing maven 3.0.5
  wget http://apache.rediris.es/maven/maven-3/3.0.5/binaries/apache-maven-3.0.5-bin.tar.gz
  tar xzf apache-maven-3.0.5-bin.tar.gz -C /usr/local
  ln -s /usr/local/apache-maven-3.0.5 /usr/local/maven
  printf "export M2_HOME=/usr/local/maven\nexport PATH=\${M2_HOME}/bin:${PATH}\n" > /etc/profile.d/maven.sh
  echo installing brunch
  npm install -g brunch@1.6.2 
SCRIPT
  config.vm.provision :shell,
  	:inline => $script
end
