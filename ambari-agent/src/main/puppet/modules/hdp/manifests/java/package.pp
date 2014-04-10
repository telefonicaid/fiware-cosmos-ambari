#
#
# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.
#
#
define hdp::java::package(
  $size
)
{
    
  include hdp::params
  
  $security_enabled = $hdp::params::security_enabled
  $jdk_bin = $hdp::params::jdk_bins[$size]
  $artifact_dir = $hdp::params::artifact_dir
  $jdk_location = $hdp::params::jdk_location
  $jdk_curl_target = "${artifact_dir}/${jdk_bin}"
  $java_env_filename = 'ambari-java-env.sh'
  $java_env_file = "/etc/profile.d/${java_env_filename}"

  if ($size == "32") {
    $java_home = $hdp::params::java32_home
  } else {
    $java_home = $hdp::params::java64_home
  }
  $java_exec = "${java_home}/bin/java"
  $java_dir = regsubst($java_home,'/[^/]+$','')

  # curl -k - ignoring unverified server ssl sertificate,
  $curl_cmd = "mkdir -p ${artifact_dir} ; curl -kf --retry 10 ${jdk_location}/${jdk_bin} -o ${jdk_curl_target}"
  exec{ "${curl_cmd} ${name}":
    command => $curl_cmd,
    creates => $jdk_curl_target,
    path    => ["/bin","/usr/bin/"],
    unless  => "test -e ${java_exec}"
  }
 
  $install_cmd = "mkdir -p ${java_dir} ; chmod +x ${jdk_curl_target}; cd ${java_dir} ; echo A | ${jdk_curl_target} -noregister > /dev/null 2>&1"
  exec{ "${install_cmd} ${name}":
    command => $install_cmd,
    unless  => "test -e ${java_exec}",
    path    => ["/bin","/usr/bin/"]
  }
 
  file { "${java_exec} ${name}":
  ensure => present
  }

  ## Cosmos fix
  # Create global profile file for java environment variables
  # This function is called by multiple packages that need java
  # The if guards from duplicate definitions of the same file
  # It will only be defined the 1st time round
  if ! defined(File[$java_env_file]) {
    file { $java_env_file :
      ensure  => present,
      path    => $java_env_file,
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      content => template("${module_name}/${java_env_filename}.erb")
    }
  }
 
  if ($security_enabled == true) {
    hdp::java::jce::package{ $name:
      java_home_dir  => $java_home,
      jdk_location => $jdk_location,
      jdk_bin => $jdk_bin
    }
  }

  anchor{"hdp::java::package::${name}::begin":} -> Exec["${curl_cmd} ${name}"] ->  Exec["${install_cmd} ${name}"] -> File["${java_exec} ${name}"] -> anchor{"hdp::java::package::${name}::end":}
  if ($security_enabled == true) {
    File["${java_exec} ${name}"] -> Hdp::Java::Jce::Package[$name] 
  }
}
