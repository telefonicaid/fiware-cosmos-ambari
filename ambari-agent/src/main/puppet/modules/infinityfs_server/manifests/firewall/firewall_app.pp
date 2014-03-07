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

class infinityfs_server::firewall::firewall_app {
  include infinityfs_server::params

  firewall { "99 HDFS blocked":
    dport  => $infinityfs_server::params::blocked_ports,
    proto  => tcp,
    action => drop
  }

  hdfs_allowed_source { $infinityfs_server::params::allowed_sources:
    all_allowed_sources => $infinityfs_server::params::allowed_sources
  }

  define hdfs_allowed_source($all_allowed_sources) {
    # Template trick to get array index for $all_allowed_sources element
    $index = 100 + inline_template('<%= all_allowed_sources.index(name) %>')
    firewall { "${index} HDFS allowed for ${name}":
     dport  => $infinityfs_server::params::blocked_ports,
     proto  => tcp,
     action => accept,
     source => $name,
   }
  }
}
