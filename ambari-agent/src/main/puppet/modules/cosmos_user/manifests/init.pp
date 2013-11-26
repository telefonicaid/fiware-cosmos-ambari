# Telefónica Digital - Product Development and Innovation
#
# THIS CODE AND INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND,
# EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE.
#
# Copyright (c) Telefónica Investigación y Desarrollo S.A.U.
# All rights reserved.

class cosmos_user($service_state) {
  include cosmos_user::params

  # Create Cosmos group
  group { $cosmos_user::params::group:
    ensure => present,
  }

  #for each user
  initialized_user {$cosmos_user::params::users_preambles:}

  #Create system user and ssh directory
  define initialized_user {
    $params_for_user = cosmos_user_params_for_user($name, $cosmos_user_config)
    notice("Initializing user: ${params_for_user['username']}")

    $ssh_service_state = $params_for_user['ssh_enabled'] ? {
      'true' => $service_state,
      default => 'uninstalled'
    }

    # Create user
    system_user{ $params_for_user['username']:
      service_state => $ssh_service_state,
    }

    # .ssh directory
    $ensure = $ssh_service_state ? {
      'uninstalled' => absent,
      default => directory,
    }
    file { $params_for_user['user_ssh_dir']:
      ensure => $ensure,
      mode => 700,
      owner => $params_for_user['username'],
      group => $cosmos_user::params::group,
    }
  }

  # Cosmos system user resource definition
  define system_user(
    $group = $cosmos_user::params::group,
    $service_state) {

    $ensure = $service_state ? {
      'uninstalled' => absent,
      default => present,
    }
    notice("user ${name} state ${ensure}")
    user { $name:
      ensure => $ensure,
      gid => $group,
      groups => [$hdp::params::user_group],
      shell => '/bin/bash',
      managehome => true,
      require => Group[$group],
    }
  }
}

# Common resources
# user SSH keys resource definition
define cosmos_user::user_keys($service_state, $params_hash) {
  $ensure = $service_state ? {
    'uninstalled' => absent,
    default => present,
  }
  file { $params_hash['ssh_private_key_file']:
    ensure => $ensure,
    mode => 600,
    owner => $params_hash['username'],
    group => $cosmos_user::params::group,
    content => $params_hash['ssh_master_private_key'],
    require => File[$params_hash['user_ssh_dir']],
  }
  file { $params_hash['ssh_public_key_file']:
    ensure => $ensure,
    mode => 644,
    owner => $params_hash['username'],
    group => $cosmos_user::params::group,
    content => $params_hash['ssh_master_public_key'],
    require => File[$params_hash['user_ssh_dir']],
  }
}

# authorized keys
define cosmos_user::authorized_keys($content, $service_state, $params_hash) {
  $ensure = $service_state ? {
    'uninstalled' => absent,
    default => present,
  }
  file { $params_hash['ssh_authorized_keys_file']:
    ensure => $ensure,
    mode => 644,
    owner => $params_hash['username'],
    group => $cosmos_user::params::group,
    content => $content,
    require => File[$params_hash['user_ssh_dir']],
  }
}

