#
# Copyright (c) 2013-2014 Telefónica Investigación y Desarrollo S.A.U.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

class infinity_server($service_state) {
  include infinity_server::params

  $ensure = $service_state ? {
    'uninstalled' => absent,
    default => $infinity_server::params::install_ensure
  }

  package { 'infinity-server':
    ensure => $ensure
  }

  class { 'infinity_firewall':
    service_state => $service_state,
    blocked_ports => $infinity_server::params::blocked_ports
  }

  file { $infinity_server::params::ssl_dir:
    ensure => "directory"
  }

  file { $infinity_server::params::ssl_certificate_file:
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0640',
    content => $infinity_server::params::ssl_certificate_content
  }

  file { $infinity_server::params::ssl_certificate_key_file:
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0640',
    content => $infinity_server::params::ssl_certificate_key_content
  }
}
