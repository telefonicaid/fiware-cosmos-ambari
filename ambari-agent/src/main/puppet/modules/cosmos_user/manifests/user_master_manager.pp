# Telefónica Digital - Product Development and Innovation
#
# THIS CODE AND INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND,
# EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE.
#
# Copyright (c) Telefónica Investigación y Desarrollo S.A.U.
# All rights reserved.

class cosmos_user::user_master_manager($service_state) inherits cosmos_user::params {

  #adds user, directories, and common configs
  class { 'cosmos_user':
    service_state => $service_state
  }

  #for each user
  user_keys_and_hdfs_dir {$cosmos_user::params::users_preambles:}

  #User ssh keys and HDFS directory
  define user_keys_and_hdfs_dir {
    $value = $name
    $params_for_user = cosmos_user_params_for_user($value, $cosmos_user_config)

    $ssh_service_state = $params_for_user['ssh_enabled'] ? {
      'true' => $service_state,
      default => 'uninstalled'
    }

    # user private, public keys
    cosmos_user::user_keys{ "${params_for_user['username']}_keys":
      service_state => $ssh_service_state,
      params_hash => $params_for_user,
    }

    # authorized keys for master
    cosmos_user::authorized_keys{ "${params_for_user['username']}_master_authorized_keys":
      content => $params_for_user['ssh_master_authorized_keys'],
      service_state => $ssh_service_state,
      params_hash => $params_for_user,
    }

    # HDFS configuration
    $hdfs_service_state = $params_for_user['hdfs_enabled'] ? {
      'true' => $service_state,
      default => 'uninstalled'
    }

    $exec_path = ["/bin","/usr/bin", "/usr/sbin"]
    # Create HDFS user home directory
    $create_command = "hadoop fs -mkdir ${params_for_user['hdfs_user_dir']}"
    case $hdfs_service_state {
      'uninstalled': {
        # Disable HDFS user home directory
        Exec[$create_command] -> exec { "hadoop fs -chown -R ${cosmos_user::params::hdfs_disabled_dir_owner} ${params_for_user['hdfs_user_dir']}":
          path => $exec_path,
          user => 'hdfs',
        }
      }
      default: {
        Exec[$create_command] -> exec { "hadoop fs -chown ${params_for_user['username']}:${cosmos_user::params::group} ${params_for_user['hdfs_user_dir']}":,
          path => $exec_path,
          user => 'hdfs',
        }
        ~> exec { "hadoop fs -chmod ${cosmos_user::params::hdfs_user_dir_mode} ${params_for_user['hdfs_user_dir']}":,
          path => $exec_path,
          user => 'hdfs',
          refreshonly => true
        }
      }
    }
    $dir_is_present = "hadoop fs -ls /user/ | grep ${params_for_user['username']}$"
    exec { $create_command:
      path => $exec_path,
      user => 'hdfs',
      unless => $dir_is_present
    }
  }
}
