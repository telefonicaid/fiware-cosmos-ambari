class cosmos_user($service_state) {
  include cosmos_user::params

  # Create Cosmos group
  group { $cosmos_user::params::group:
    ensure => present,
  }

  # Create user
  system_user{ $cosmos_user::params::user:
    service_state => $service_state,
  }

  $wipeoff_data = true
  # .ssh directory
  hdp::directory { $cosmos_user::params::user_ssh_dir:
    ensure => directory,
    mode => 700,
    service_state => $service_state,
    force => true,
    owner => $cosmos_user::params::user,
    group => $cosmos_user::params::group,
    override_owner => true,
  }

  # Cosmos system user resource definition
  define system_user(
    $username = $cosmos_user::params::user,
    $password = $cosmos_user::params::password,
    $group = $cosmos_user::params::group,
    $service_state = 'running') {
    if ($service_state == 'uninstalled') {
      notice("Removing user: ${username}")
      user { $username:
        ensure => absent,
      }
    } else {
      notice("Creating user: ${username}")
      user { $username:
        ensure => present,
        gid => $group,
        groups => [$hdp::params::user_group],
        shell => '/bin/bash',
        managehome => true,
        password => $password,
        require => Group[$cosmos_user::params::group],
      }
    }
  }
}

