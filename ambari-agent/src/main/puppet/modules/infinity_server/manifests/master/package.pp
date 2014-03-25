# Telefónica Digital - Product Development and Innovation
#
# THIS CODE AND INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND,
# EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE.
#
# Copyright (c) Telefónica Investigación y Desarrollo S.A.U.
# All rights reserved.

class infinity_server::master::package {
  include infinity_server::params, infinity_server::firewall::firewall_pre

  notice("Installing Infinity Server")

  resources { "firewall":
    purge => true
  }

  package { $infinity_server::params::package_and_service_name_master:
    ensure => installed
  }

  anchor {'infinity_server::master::package::begin': }
    -> Class['infinity_server::firewall::firewall_pre']
    anchor {'infinity_server::master::package::end': }
}
