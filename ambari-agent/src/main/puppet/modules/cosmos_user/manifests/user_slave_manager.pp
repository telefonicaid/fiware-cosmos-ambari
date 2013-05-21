class cosmos_user::user_slave_manager($service_state) inherits cosmos_user::params {

  #adds user, directories, and common configs
  class { 'cosmos_user':
    service_state => $service_state
  }

  # authorized keys for slave
  # only set slave content if master is not also slave (1-node cluster configuration)
  # so as not to replace master authorized keys
  if ($cosmos_user::params::master != $hostname) {
    cosmos_user::authorized_keys{ "${cosmos_user::params::user}_slave_authorized_keys":
      content => $cosmos_user::params::ssh_slave_authorized_keys,
      service_state => $service_state,
    }
  }
}
