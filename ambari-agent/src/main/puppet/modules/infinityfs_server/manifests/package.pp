# Telefónica Digital - Product Development and Innovation
#
# THIS CODE AND INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND,
# EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE.
#
# Copyright (c) Telefónica Investigación y Desarrollo S.A.U.
# All rights reserved.

class infinityfs_server::package {
  include infinityfs_server::params, infinityfs_server::firewall::firewall_pre

  notice("Installing Infinity Server")

  resources { "firewall":
    purge => true
  }

  anchor {'infinityfs_server::package::begin': }
    -> Class['infinityfs_server::firewall::firewall_pre']
    anchor {'infinityfs_server::package::end': }
}
