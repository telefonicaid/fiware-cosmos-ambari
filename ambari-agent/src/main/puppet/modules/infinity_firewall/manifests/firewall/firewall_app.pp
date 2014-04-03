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

class infinity_firewall::firewall::firewall_app($blocked_ports) {
  include infinity_firewall::params

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

  allowed_source { $infinity_firewall::params::allowed_sources:
    all_allowed_sources => $infinity_firewall::params::allowed_sources,
    allowed_ports       => $blocked_ports
  }

  define allowed_source($all_allowed_sources, $allowed_ports) {
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
