# Telefónica Digital - Product Development and Innovation
#
# THIS CODE AND INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND,
# EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE.
#
# Copyright (c) Telefónica Investigación y Desarrollo S.A.U.
# All rights reserved.

class infinity_driver($service_state) {
  include infinity_driver::params

  $ensure = $service_state ? {
    'uninstalled' => absent,
    default => $infinity_driver::params::install_ensure,
  }

  package { 'infinity-driver':
    ensure => $ensure
  }
}
