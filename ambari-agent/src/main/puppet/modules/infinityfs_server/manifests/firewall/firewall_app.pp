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

class infinityfs_server::firewall::firewall_app($blocked_ports) {
  include infinityfs_server::params

  firewall { "999 HDFS blocked":
    dport  => $blocked_ports,
    proto  => tcp,
    action => drop
  }

  firewall { '100 HDFS allowed for localhost':
    dport  => $blocked_ports,
    proto  => tcp,
    action => accept,
    source => '127.0.0.1',
  }

  hdfs_allowed_source { $infinityfs_server::params::allowed_sources:
    all_allowed_sources => $infinityfs_server::params::allowed_sources,
    allowed_ports       => $blocked_ports
  }

  define hdfs_allowed_source($all_allowed_sources, $allowed_ports) {
    # Template trick to get array index for $all_allowed_sources element
    $index = 101 + inline_template('<%= all_allowed_sources.index(name) %>')
    firewall { "${index} HDFS allowed for ${name}":
     dport  => $allowed_ports,
     proto  => tcp,
     action => accept,
     source => $name,
    }
  }
}
