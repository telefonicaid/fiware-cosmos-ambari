# Telefónica Digital - Product Development and Innovation
#
# THIS CODE AND INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND,
# EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE.
#
# Copyright (c) Telefónica Investigación y Desarrollo S.A.U.
# All rights reserved.

class cosmos_user::user_slave_manager($service_state) inherits cosmos_user::params {

  #adds user, directories, and common configs
  class { 'cosmos_user':
    service_state => $service_state
  }

  # authorized keys for slave
  # only set slave content if master is not also slave (1-node cluster configuration)
  # so as not to replace master authorized keys
  if ($cosmos_user::params::master != $hostname) {
    #for each user
    user_slave_keys {$cosmos_user::params::users_preambles:}
  }

  # User's authorized ssh keys on slave machine
  define user_slave_keys {
    $params_for_user = cosmos_user_params_for_user($name, $cosmos_user_config)

    $ssh_service_state = $params_for_user['ssh_enabled'] ? {
      'true' => $service_state,
      default => 'uninstalled'
    }

    cosmos_user::authorized_keys{ "${$params_for_user['username']}_slave_authorized_keys":
      content => $params_for_user['ssh_slave_authorized_keys'],
      service_state => $ssh_service_state,
      params_hash => $params_for_user,
    }
  }
}
