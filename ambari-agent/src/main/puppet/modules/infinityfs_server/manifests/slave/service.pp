# Telefónica Digital - Product Development and Innovation
#
# THIS CODE AND INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND,
# EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE.
#
# Copyright (c) Telefónica Investigación y Desarrollo S.A.U.
# All rights reserved.

class infinityfs_server::slave::service($service_state) {
  include infinityfs_server::params

  notice("Starting Infinity Nginx Proxy Server")

  class { 'firewall':
    ensure => $service_state
  }

  class { 'infinityfs_server::firewall::firewall_app' :
      blocked_ports => $infinityfs_server::params::blocked_ports_slave
  }

  service { $infinityfs_server::params::package_and_service_name_slave :
    ensure => $service_state
  }

  anchor {'infinityfs_server::slave::service::begin': }
    -> Class['firewall']
    -> Class['infinityfs_server::firewall::firewall_app']
    -> Service[$infinityfs_server::params::package_and_service_name_slave]
    anchor {'infinityfs_server::slave::service::end': }
}
