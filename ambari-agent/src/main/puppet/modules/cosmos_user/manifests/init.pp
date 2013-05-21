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

  # Force deletion on uninstall. This variable is used by hdp::directory.
  # It is defined in hdp::params originally.
  # We employ variable scoping to enforce wipeoff only for this resource, not globally.
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
    $service_state) {

    $ensure = $service_state ? {
      'uninstalled' => absent,
      default => present,
    }
    notice("user ${username} state ${ensure}")
    user { $username:
      ensure => $ensure,
      gid => $group,
      groups => [$hdp::params::user_group],
      shell => '/bin/bash',
      managehome => true,
      require => Group[$cosmos_user::params::group],
    }
  }
}

# Common resources
# user SSH keys resource definition
define cosmos_user::user_keys($service_state) {
  $ensure = $service_state ? {
    'uninstalled' => absent,
    default => present,
  }
  file { $cosmos_user::params::ssh_private_key_file:
    ensure => $ensure,
    mode => 600,
    owner => $cosmos_user::params::user,
    group => $cosmos_user::params::group,
    content => $cosmos_user::params::ssh_master_private_key,
    require => File[$cosmos_user::params::user_ssh_dir],
  }
  file { $cosmos_user::params::ssh_public_key_file:
    ensure => $ensure,
    mode => 644,
    owner => $cosmos_user::params::user,
    group => $cosmos_user::params::group,
    content => $cosmos_user::params::ssh_master_public_key,
    require => File[$cosmos_user::params::user_ssh_dir],
  }
}

# authorized keys
define cosmos_user::authorized_keys($content, $service_state) {
  $ensure = $service_state ? {
    'uninstalled' => absent,
    default => present,
  }
  file { $cosmos_user::params::ssh_authorized_keys_file:
    ensure => $ensure,
    mode => 644,
    owner => $cosmos_user::params::user,
    group => $cosmos_user::params::group,
    content => $content,
    require => File[$cosmos_user::params::user_ssh_dir],
  }
}

