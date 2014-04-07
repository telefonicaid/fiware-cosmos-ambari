# Telefónica Digital - Product Development and Innovation
#
# THIS CODE AND INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND,
# EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE.
#
# Copyright (c) Telefónica Investigación y Desarrollo S.A.U.
# All rights reserved.

class infinity_server::params inherits hdp::params {
  $infinity_configuration          = $configuration['infinity-server']

  $blocked_ports_master            = split($infinity_configuration['blocked_ports_master'], ',')
  $blocked_ports_slave             = split($infinity_configuration['blocked_ports_slave'], ',')
  #TODO: Inject $server_port_master to infinity-server config
  $server_port_master              = $infinity_configuration['server_port_master']
  $server_port_slave               = $infinity_configuration['server_port_slave']
  $proxy_secure_phrase_template    = $infinity_configuration['proxy_secure_phrase_template']
  $hdfs_datanode_port              = $infinity_configuration['hdfs_datanode_port']
  $hdfs_datanode_address           = "http://${::ipaddress}:${hdfs_datanode_port}"

  #SSL Parameters
  $ssl_certificate_content         = $infinity_configuration['ssl_certificate_content']
  $ssl_certificate_key_content     = $infinity_configuration['ssl_certificate_key_content']
  $ssl_dir                         = '/etc/ssl/cosmos'
  $ssl_certificate_file            = "${ssl_dir}/cosmos_cer.pem"
  $ssl_certificate_key_file        = "${ssl_dir}/cosmos_key.pem"

  $allowed_sources                 = $hdp::params::all_hosts
  $package_and_service_name_master = 'infinity-server'
  $package_and_service_name_slave  = 'nginx'
}
