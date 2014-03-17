# Telefónica Digital - Product Development and Innovation
#
# THIS CODE AND INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND,
# EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE.
#
# Copyright (c) Telefónica Investigación y Desarrollo S.A.U.
# All rights reserved.

class infinityfs_server::params inherits hdp::params {
  $infinity_configuration          = $configuration['infinityfs_server']

  $blocked_ports_master            = split($infinity_configuration['blocked_ports_master'], ',')
  $blocked_ports_slave             = split($infinity_configuration['blocked_ports_slave'], ',')
  $infinity_server_port            = $infinity_configuration['server_port']
  $infinity_secure_phrase_template = $infinity_configuration['secure_phrase_template']
  $hdfs_datanode_address           = $infinity_configuration['hdfs_datanode_address']

  $allowed_sources                 = $hdp::params::all_hosts
  $package_and_service_name_master = 'infinity-server'
  $package_and_service_name_slave  = 'nginx'
}
