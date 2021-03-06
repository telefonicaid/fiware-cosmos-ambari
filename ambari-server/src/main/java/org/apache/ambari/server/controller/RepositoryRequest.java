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

public class RepositoryRequest extends OperatingSystemRequest{

  private String repoId;
  private String baseUrl;
  
  public RepositoryRequest(String stackName, String stackVersion, String osType, String repoId) {
    super(stackName, stackVersion, osType);
    setRepoId(repoId);
  }

  public String getRepoId() {
    return repoId;
  }

  public void setRepoId(String repoId) {
    this.repoId = repoId;
  }
  
  /**
   * Gets the base URL for the repo.
   * 
   * @return the url
   */
  public String getBaseUrl() {
    return baseUrl;
  }
  
  /**
   * Sets the base URL for the repo.
   * 
   * @param url the base URL.
   */
  public void setBaseUrl(String url) {
    baseUrl = url;
  }
  
  

}
