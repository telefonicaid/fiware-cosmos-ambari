  #
#  Licensed to the Apache Software Foundation (ASF) under one
#  or more contributor license agreements.  See the NOTICE file
#  distributed with this work for additional information
#  regarding copyright ownership.  The ASF licenses this file
#  to you under the Apache License, Version 2.0 (the
#  "License"); you may not use this file except in compliance
#  with the License.  You may obtain a copy of the License at
# 
#      http://www.apache.org/licenses/LICENSE-2.0
# 
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.

from ambari_client.model import  host
__docformat__ = "epytext"


def create_host(root_resource,  host_name, ip, rack_info=None):
  """
  Create a host
  @param root_resource: The root Resource.
  @param host_name: Host name
  @param ip: IP address
  @param rack_info: Rack id. Default None
  @return: An HostModel object
  """
  return host.create_host(root_resource,  host_name, ip, rack_info=None)

def get_host(root_resource, host_name):
  """
  Lookup a host by id
  @param root_resource: The root Resource.
  @param host_name: Host name
  @return: An HostModel object
  """
  return host.get_host(root_resource, host_name)



def get_all_hosts(root_resource):
  """
  Get all hosts
  @param root_resource: The root Resource.
  @return: A list of HostModel objects.
  """
  return host.get_all_hosts(root_resource)




def delete_host(root_resource, host_name):
  """
  Delete a host by id
  @param root_resource: The root Resource.
  @param host_name: Host name
  @return: The deleted HostModel object
  """
  return host.delete_host(root_resource,host_name)



def bootstrap_hosts(root_resource , hosts_list ,ssh_key):
  """
  Bootstrap hosts.
  @param hosts list of host_names.
  @return: A  StatusModel object.
  """
  return host.bootstrap_hosts(root_resource, hosts_list ,ssh_key)