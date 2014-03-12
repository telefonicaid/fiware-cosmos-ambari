# Telefónica Digital - Product Development and Innovation
#
# THIS CODE AND INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND,
# EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE.
#
# Copyright (c) Telefónica Investigación y Desarrollo S.A.U.
# All rights reserved.

class infinityfs_server::params (
  $basedir         = '/opt/pdi-cosmos',
  $blocked_ports   = [8020, 9000, 50010, 50020, 50070, 50075],
  $allowed_sources = $hdp::params::all_hosts
) inherits hdp::params {
  $confdir = "${basedir}/etc"
  $vardir  = "${basedir}/var"
  $logdir  = "${vardir}/log"
}
