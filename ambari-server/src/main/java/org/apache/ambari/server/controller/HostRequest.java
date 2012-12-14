/**
 * Licensed to the Apache Software Foundation (ASF) under one
 * or more contributor license agreements.  See the NOTICE file
 * distributed with this work for additional information
 * regarding copyright ownership.  The ASF licenses this file
 * to you under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance
 * with the License.  You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package org.apache.ambari.server.controller;

import java.util.List;
import java.util.Map;
import java.util.Map.Entry;

public class HostRequest {

  private String hostname;
  private String publicHostname;
  private List<String> clusterNames; // CREATE/UPDATE
  private Map<String, String> hostAttributes; // CREATE/UPDATE
  private String rackInfo;

  public HostRequest(String hostname, List<String> clusterNames, Map<String, String> hostAttributes) {
    this.hostname = hostname;
    this.clusterNames = clusterNames;
    this.hostAttributes = hostAttributes;
  }

  public String getHostname() {
    return hostname;
  }

  public void setHostname(String hostname) {
    this.hostname = hostname;
  }

  public List<String> getClusterNames() {
    return clusterNames;
  }

  public void setClusterNames(List<String> clusterNames) {
    this.clusterNames = clusterNames;
  }

  public Map<String, String> getHostAttributes() {
    return hostAttributes;
  }

  public void setHostAttributes(Map<String, String> hostAttributes) {
    this.hostAttributes = hostAttributes;
  }
  
  public String getRackInfo() {
    return rackInfo;
  }
  
  public void setRackInfo(String info) {
    rackInfo = info;
  }
  
  public String getPublicHostName() {
    return publicHostname;
  }
  
  public void setPublicHostName(String name) {
    publicHostname = name;
  }

  public String toString() {
    StringBuilder sb = new StringBuilder();
    sb.append("{"
        + ", hostname=" + hostname
        + ", clusterNames=[");
    if (clusterNames != null) {
      for (int i = 0; i < clusterNames.size(); ++i) {
        if (i != 0) {
          sb.append(",");
        }
        sb.append(clusterNames.get(i));
      }
    }
    if (hostAttributes != null) {
      sb.append("], hostAttributes=[");
      int i = 0;
      for (Entry<String, String> attr : hostAttributes.entrySet()) {
        if (i != 0) {
          sb.append(",");
        }
        ++i;
        sb.append(attr.getKey() + "=" + attr.getValue());
      }
    }
    sb.append("] }");
    return sb.toString();
  }

}