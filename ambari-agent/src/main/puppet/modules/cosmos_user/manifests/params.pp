# Telefónica Digital - Product Development and Innovation
#
# THIS CODE AND INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND,
# EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE.
#
# Copyright (c) Telefónica Investigación y Desarrollo S.A.U.
# All rights reserved.

class cosmos_user::params inherits hdp::params {

  if has_key($configuration, 'cosmos-user') {
    $cosmos_user_config = $configuration['cosmos-user']
    notice("Number of Cosmos users: ${cosmos_user_config['number_of_users']}")
    $users_preambles = cosmos_user_range('1', $cosmos_user_config['number_of_users'])
  }

  $group = hdp_default('group', 'cosmos')
  $hdfs_user_dir_mode = 700
  $hdfs_disabled_dir_mode = 700
  $hdfs_disabled_dir_owner = 'hdfs'
}
