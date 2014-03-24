# Telefónica Digital - Product Development and Innovation
#
# THIS CODE AND INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND,
# EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE.
#
# Copyright (c) Telefónica Investigación y Desarrollo S.A.U.
# All rights reserved.

class infinity_server::master($service_state) {

  case $service_state {
    'installed_and_configured' : {
      include infinity_server::master::package
      anchor {'infinity_server::master::begin' :}
        -> Class['infinity_server::master::package']
        -> anchor {'infinity_server::master::end': }
    }
    'running', 'stopped' :       {
      class { 'infinity_server::master::service':
        service_state => $service_state
      }
      anchor {'infinity_server::master::begin' :}
        -> Class['infinity_server::master::service']
        -> anchor {'infinity_server::master::end': }
    }
  }
}
