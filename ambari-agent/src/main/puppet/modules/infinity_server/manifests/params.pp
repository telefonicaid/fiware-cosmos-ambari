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

class infinity_server::params inherits hdp::params {
  $infinity_configuration          = $configuration['infinity-server']

  $install_ensure                  = 'latest'
  $blocked_ports                   = split($infinity_configuration['blocked_ports'], ',')

  #SSL Parameters
  $ssl_certificate_content         = $infinity_configuration['ssl_certificate_content']
  $ssl_certificate_key_content     = $infinity_configuration['ssl_certificate_key_content']
  $ssl_dir                         = '/etc/ssl/cosmos'
  $ssl_certificate_file            = "${ssl_dir}/cosmos_cer.pem"
  $ssl_certificate_key_file        = "${ssl_dir}/cosmos_key.pem"

  $allowed_sources                 = $hdp::params::all_hosts
}
