# Telefónica Digital - Product Development and Innovation
#
# THIS CODE AND INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND,
# EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE.
#
# Copyright (c) Telefónica Investigación y Desarrollo S.A.U.
# All rights reserved.

class infinityfs_server($service_state) {

  case $service_state {
    'installed_and_configured' : {
      include infinityfs_server::package, infinityfs_server::config
      anchor {'infinityfs_server::begin' :}
        -> Class['infinityfs_server::package']
        -> Class['infinityfs_server::config']
        -> anchor {'infinityfs_server::end': }
    }
    'running', 'stopped' :       {
      class { 'infinityfs_server::service':
        service_state => $service_state
      }
      anchor {'infinityfs_server::begin' :}
        -> Class['infinityfs_server::service']
        -> anchor {'infinityfs_server::end': }
    }
  }
}
