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

    # user private, public keys
    cosmos_user::user_keys{ "${params_for_user['username']}_keys":
      service_state => $service_state,
      params_hash => $params_for_user,
    }

    # authorized keys for master
    cosmos_user::authorized_keys{ "${params_for_user['username']}_master_authorized_keys":
      content => $params_for_user['ssh_master_authorized_keys'],
      service_state => $service_state,
      params_hash => $params_for_user,
    }

    # Create HDFS user home directory
    hdp-hadoop::hdfs::directory{ $params_for_user['hdfs_user_dir']:
      mode            => $cosmos_user::params::hdfs_user_dir_mode,
      owner           => $params_for_user['username'],
      recursive_chmod => true
    }
  }
}
