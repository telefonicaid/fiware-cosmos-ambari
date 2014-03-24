# Telefónica Digital - Product Development and Innovation
#
# THIS CODE AND INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND,
# EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE.
#
# Copyright (c) Telefónica Investigación y Desarrollo S.A.U.
# All rights reserved.

class infinity_server::master::service($service_state) {
  include infinity_server::params

  notice("Starting Infinity Server")

  class { 'firewall':
    ensure => $service_state
  }

  class { 'infinity_server::firewall::firewall_app' :
      blocked_ports => $infinity_server::params::blocked_ports_master
  }

  service { $infinity_server::params::package_and_service_name_master :
    ensure => $service_state
  }

  anchor {'infinity_server::service::begin': }
    -> Class['firewall']
    -> Class['infinity_server::firewall::firewall_app']
    -> Service[$infinity_server::params::package_and_service_name_master]
    anchor {'infinity_server::service::end': }
}
