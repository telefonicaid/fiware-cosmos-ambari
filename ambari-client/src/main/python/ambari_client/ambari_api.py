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

import logging
from ambari_client.core.http_client import HttpClient
from ambari_client.resources import  clusters ,hosts
from ambari_client.core.rest_resource import RestResource

__docformat__ = "epytext"

LOG = logging.getLogger(__name__)


API_VERSION = 1




class AmbariClient(RestResource):
  """
  AmbariClient top-level root resources.
  """

  def __init__(self, host_name, port=None,user_name="admin", password="admin",
               version=API_VERSION , client = None):
    """
    Creates a RestResource object.

    @param host_name: The hostname  server.
    @param port: The port of the server. 
    @param user_name: Login name.
    @param password: Login password.
    @param version: API version.
    @return RestResource object referring to the root.
    """
    
    self._version = version
    protocol = "http"
    if port is None: 
      port = 8080
    host_url = "%s://%s:%s/api/v%s" %(protocol, host_name, port, version)
    if client is None:
        client = HttpClient(host_url, user_name , password )
    RestResource.__init__(self, client)



  @property
  def version(self):
    """
    Returns the API version .
    """
    return self._version


  def get_all_clusters(self):
    """
    Get all clusters.
    @return: A list of ModelList.
    """
    return clusters.get_all_clusters(self)




  def get_cluster(self, cluster_name):
    """
    Get a cluster by cluster_name.

    @param cluster_name Cluster cluster_name.
    @return An ClusterModel.
    """
    return clusters.get_cluster(self, cluster_name)



  def get_all_hosts(self):
    """
    Get all hosts
    @return: A list of HostModel objects.
    """
    return hosts.get_all_hosts(self)


  def get_request_status(self , request_path):
    """
    Get request status
    @return: A  StatusModel object.
    """
    return "TODO"


  def bootstrap_hosts(self , hosts_list ,ssh_key):
    """
    Bootstrap hosts.
    @param hosts list of host_names.
    @return: A  StatusModel object.
    """
    return hosts.bootstrap_hosts(self, hosts_list ,ssh_key)


  def create_cluster(self, cluster_name, version):
    """
    Create a new cluster.
    @param name Cluster name.
    @param version HDP version.
    @return  ClusterModel object.
    """
    return clusters.create_cluster(self, cluster_name, version)  



  def delete_cluster(self ,cluster_name):
    """
    Create a cluster
    @param root_resource: The root Resource.
    @param cluster_name: Cluster cluster_name
    """
    return clusters.delete_cluster(self, cluster_name)



def get_root_resource(server_host, server_port=None,username="admin", password="admin",
                       version=1):
  """
   AmbariClient.
  """
  return AmbariClient(server_host, server_port, username, password, version)
