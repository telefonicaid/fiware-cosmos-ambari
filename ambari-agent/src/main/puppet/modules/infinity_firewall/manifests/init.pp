# Telefónica Digital - Product Development and Innovation
#
# THIS CODE AND INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND,
# EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE.
#
# Copyright (c) Telefónica Investigación y Desarrollo S.A.U.
# All rights reserved.

class infinity_firewall($service_state, $blocked_ports) {

  case $service_state {
    'installed_and_configured' : {
      resources { "firewall":
        purge => true
      }
      include infinity_firewall::firewall::firewall_pre

      class { 'firewall': }

      class { 'infinity_firewall::firewall::firewall_app' :
        blocked_ports => $blocked_ports
      }

      anchor{'infinity_firewall::begin' :}
      -> Resources['firewall']
      -> Class['infinity_firewall::firewall::firewall_pre']
      -> Class['firewall']
      -> Class['infinity_firewall::firewall::firewall_app']
      -> anchor{'infinity_firewall::end' :}
    }
  }
}
