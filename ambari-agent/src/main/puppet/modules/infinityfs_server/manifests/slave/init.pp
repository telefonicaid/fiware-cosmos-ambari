# Telefónica Digital - Product Development and Innovation
#
# THIS CODE AND INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND,
# EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE.
#
# Copyright (c) Telefónica Investigación y Desarrollo S.A.U.
# All rights reserved.

class infinityfs_server::slave($service_state) {

  case $service_state {
    'installed_and_configured' : {
      include infinityfs_server::slave::package, infinityfs_server::slave::config
      anchor {'infinityfs_server::slave::begin' :}
        -> Class['infinityfs_server::slave::package']
        -> Class['infinityfs_server::slave::config']
        -> anchor {'infinityfs_server::slave::end': }
    }
    'running', 'stopped' :       {
      class { 'infinityfs_server::slave::service':
        service_state => $service_state
      }
      anchor {'infinityfs_server::slave::begin' :}
        -> Class['infinityfs_server::slave::service']
        -> anchor {'infinityfs_server::slave::end': }
    }
  }
}
