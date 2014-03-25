# Telefónica Digital - Product Development and Innovation
#
# THIS CODE AND INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND,
# EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE.
#
# Copyright (c) Telefónica Investigación y Desarrollo S.A.U.
# All rights reserved.

class infinity_server::slave::config inherits infinity_server::params {
  $nginx_conf_dir = '/etc/nginx/conf.d'

  file { $nginx_conf_dir :
    ensure => directory,
    purge => true,
    recurse => true,
    force => true
  }

  file { "${nginx_conf_dir}/infinity-proxy.conf" :
    ensure    => present,
    owner     => 'root',
    group     => 'root',
    mode      => '0644',
    content   => template('infinity_server/infinity-proxy.conf.erb'),
  }
}
