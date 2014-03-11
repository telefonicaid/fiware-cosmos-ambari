# Telefónica Digital - Product Development and Innovation
#
# THIS CODE AND INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND,
# EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE.
#
# Copyright (c) Telefónica Investigación y Desarrollo S.A.U.
# All rights reserved.

class infinityfs_server::service($service_state) {
  include infinityfs_server::firewall::firewall_app

  notice("Starting Infinity Server")

  class { 'firewall':
    ensure => $service_state
  }

  anchor {'infinityfs_server::service::begin': }
    -> Class['firewall']
    -> Class['infinityfs_server::firewall::firewall_app']
    anchor {'infinityfs_server::service::end': }
}
