class cosmos_user::user_master_manager($service_state) inherits cosmos_user::params {

  #adds user, directories, and common configs
  class { 'cosmos_user':
    service_state => $service_state
  }

  # user private, public keys
  cosmos_user::user_keys{ "${cosmos_user::params::user}_keys":
    service_state => $service_state,
  }

  # authorized keys for master
  cosmos_user::authorized_keys{ "${cosmos_user::params::user}_master_authorized_keys":
    content => $cosmos_user::params::ssh_master_authorized_keys,
    service_state => $service_state,
  }

  # Create HDFS user home directory
  hdp-hadoop::hdfs::directory{ $cosmos_user::params::hdfs_user_dir:
     service_state   => $service_state,
     mode            => $cosmos_user::params::hdfs_user_dir_mode,
     owner           => $cosmos_user::params::user,
     recursive_chmod => true
  }
}
