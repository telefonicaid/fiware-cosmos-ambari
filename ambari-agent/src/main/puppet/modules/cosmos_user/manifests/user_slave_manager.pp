class cosmos_user::user_slave_manager($service_state) inherits cosmos_user::params {

  #adds user, directories, and common configs
  class { 'cosmos_user':
    service_state => $service_state
  }

  authorized_keys{ "${cosmos_user::params::user}_authorized_keys":}

  define authorized_keys {
    file { $cosmos_user::params::ssh_authorized_keys_file:
      ensure => present,
      mode => 644,
      owner => $cosmos_user::params::user,
      group => $cosmos_user::params::group,
      content => $cosmos_user::params::ssh_authorized_keys,
      require => File[$cosmos_user::params::user_ssh_dir],
    }
  }
}
