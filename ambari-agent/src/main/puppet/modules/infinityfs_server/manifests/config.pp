# Telefónica Digital - Product Development and Innovation
#
# THIS CODE AND INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND,
# EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE.
#
# Copyright (c) Telefónica Investigación y Desarrollo S.A.U.
# All rights reserved.

class infinityfs_server::config {
  include infinityfs_server::params

  notice("Configuring Infinity Server")

  $infinity_directories = [
    $infinityfs_server::params::confdir,
    $infinityfs_server::params::vardir,
    $infinityfs_server::params::logdir
  ]

  file { $infinity_directories:
    ensure => 'directory',
    mode   => '0440',
  }

  file { 'logback.conf':
    ensure  => 'present',
    path    => "${infinityfs_server::params::confdir}/logback.conf",
    mode    => '0644',
    content => template("infinityfs_server/logback.conf.erb"),
  }

  file { 'infinity-server.conf':
    ensure  => 'present',
    path    => "${infinityfs_server::params::confdir}/infinity-server.conf",
    mode    => '0644',
    content => template("infinityfs_server/infinity-server.conf.erb"),
  }
}
