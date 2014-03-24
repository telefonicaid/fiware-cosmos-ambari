# Telefónica Digital - Product Development and Innovation
#
# THIS CODE AND INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND,
# EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE.
#
# Copyright (c) Telefónica Investigación y Desarrollo S.A.U.
# All rights reserved.

class infinity_server::slave($service_state) {

  case $service_state {
    'installed_and_configured' : {
      include infinity_server::slave::package, infinity_server::slave::config
      anchor {'infinity_server::slave::begin' :}
        -> Class['infinity_server::slave::package']
        -> Class['infinity_server::slave::config']
        -> anchor {'infinity_server::slave::end': }
    }
    'running', 'stopped' :       {
      class { 'infinity_server::slave::service':
        service_state => $service_state
      }
      anchor {'infinity_server::slave::begin' :}
        -> Class['infinity_server::slave::service']
        -> anchor {'infinity_server::slave::end': }
    }
  }
}
