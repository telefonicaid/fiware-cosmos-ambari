# Telefónica Digital - Product Development and Innovation
#
# THIS CODE AND INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND,
# EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE.
#
# Copyright (c) Telefónica Investigación y Desarrollo S.A.U.
# All rights reserved.

class infinity_server::slave::service($service_state) {
  include infinity_server::params

  notice("Starting Infinity Nginx Proxy Server")

  class { 'firewall':
    ensure => $service_state
  }

  class { 'infinity_server::firewall::firewall_app' :
      blocked_ports => $infinity_server::params::blocked_ports_slave
  }

  service { $infinity_server::params::package_and_service_name_slave :
    ensure => $service_state
  }

  anchor {'infinity_server::slave::service::begin': }
    -> Class['firewall']
    -> Class['infinity_server::firewall::firewall_app']
    -> Service[$infinity_server::params::package_and_service_name_slave]
    anchor {'infinity_server::slave::service::end': }
}
