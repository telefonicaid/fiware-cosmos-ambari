# Telefónica Digital - Product Development and Innovation
#
# THIS CODE AND INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND,
# EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE.
#
# Copyright (c) Telefónica Investigación y Desarrollo S.A.U.
# All rights reserved.

class infinityfs_server::slave::package {
  include infinityfs_server::params, infinityfs_server::firewall::firewall_pre

  notice("Installing Infinity Server")

  resources { "firewall":
    purge => true
  }

  package { $infinityfs_server::params::package_and_service_name_slave:
    ensure => installed
  }

  anchor {'infinityfs_server::slave::package::begin': }
    -> Class['infinityfs_server::firewall::firewall_pre']
    anchor {'infinityfs_server::slave::package::end': }
}
