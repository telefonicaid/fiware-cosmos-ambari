class cosmos_user::user_master_manager($service_state) inherits cosmos_user::params {

  #adds user, directories, and common configs
  class { 'cosmos_user':
    service_state => $service_state
  }

  # user private, public keys
  if ($service_state == 'uninstalled') {
    user_keys{ "${cosmos_user::params::user}_keys":
      ensure => absent,
    }
  } else {
    user_keys{ "${cosmos_user::params::user}_keys":
      ensure => present,
    }
  }

  # Create HDFS user home directory
  hdp-hadoop::hdfs::directory{ $cosmos_user::params::hdfs_user_dir:
     service_state   => $service_state,
     mode            => $cosmos_user::params::hdfs_user_dir_mode,
     owner           => $cosmos_user::params::user,
     recursive_chmod => true
  }

  # user SSH keys resource definition
  define user_keys($ensure) {
    file { $cosmos_user::params::ssh_private_key_file:
      ensure => $ensure,
      mode => 600,
      owner => $cosmos_user::params::user,
      group => $cosmos_user::params::group,
      content => $cosmos_user::params::ssh_private_key,
      require => File[$cosmos_user::params::user_ssh_dir],
    }

    file { $cosmos_user::params::ssh_public_key_file:
      ensure => $ensure,
      mode => 644,
      owner => $cosmos_user::params::user,
      group => $cosmos_user::params::group,
      content => $cosmos_user::params::ssh_public_key,
      require => File[$cosmos_user::params::user_ssh_dir],
    }
  }

}
