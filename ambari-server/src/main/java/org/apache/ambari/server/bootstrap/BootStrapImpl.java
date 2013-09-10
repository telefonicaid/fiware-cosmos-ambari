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

package org.apache.ambari.server.bootstrap;

import java.io.File;
import java.io.IOException;
import java.net.InetAddress;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

import org.apache.ambari.server.api.services.AmbariMetaInfo;
import org.apache.ambari.server.bootstrap.BSResponse.BSRunStat;
import org.apache.ambari.server.configuration.Configuration;
import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;

import com.google.inject.Inject;
import com.google.inject.Singleton;
import org.apache.ambari.server.controller.AmbariServer;

@Singleton
public class BootStrapImpl {
  public static final String DEV_VERSION = "${ambariVersion}";
  private File bootStrapDir;
  private String bootstrapActionScript;
  private String bootSetupAgentScript;
  private String teardownAgentScript;
  private String bootSetupAgentPassword;
  private BSActionRunner bsActionRunner;
  private String masterHostname;

  private static Log LOG = LogFactory.getLog(BootStrapImpl.class);

  /* Monotonically increasing requestid for the bootstrap api to query on */
  int requestId = 0;
  private FifoLinkedHashMap<Long, BootStrapRequest> bsStatus;
  private Set<String> hostsInProcess;
  private final String clusterOsType;
  private String projectVersion;
  private int serverPort;

  @Inject
  public BootStrapImpl(Configuration conf, AmbariMetaInfo ambariMetaInfo) throws IOException {
    this.bootStrapDir = conf.getBootStrapDir();
    this.bootstrapActionScript = conf.getBootStrapActionScript();
    this.bootSetupAgentScript = conf.getBootSetupAgentScript();
    this.bootSetupAgentPassword = conf.getBootSetupAgentPassword();
    this.teardownAgentScript = conf.getTeardownAgentScript();
    this.bsStatus = new FifoLinkedHashMap<Long, BootStrapRequest>();
    this.hostsInProcess = new HashSet<String>();
    this.masterHostname = conf.getMasterHostname(
        InetAddress.getLocalHost().getCanonicalHostName());
    this.clusterOsType = conf.getServerOsType();
    this.projectVersion = ambariMetaInfo.getServerVersion();
    this.projectVersion = (this.projectVersion.equals(DEV_VERSION)) ? DEV_VERSION.replace("$", "") : this.projectVersion;
    this.serverPort = (conf.getApiSSLAuthentication())? conf.getClientSSLApiPort() : conf.getClientApiPort();
  }

  /**
   * Return {@link BootStrapRequest} for a given responseId.
   * @param requestId the responseId for which the status needs to be returned.
   * @return status for a specific response id. A response Id of -1 means the
   * latest responseId.
   */
  public synchronized BootStrapRequest getStatus(long requestId) {
    if (! bsStatus.containsKey(Long.valueOf(requestId))) {
      return null;
    }
    return bsStatus.get(Long.valueOf(requestId));
  }

  /**
   * update status of a request. Mostly called by the status collector thread.
   * @param requestId the request id.
   * @param status the status of the update.
   */
  synchronized void updateStatus(long requestId, BootStrapRequest status) {
    bsStatus.put(requestId, status);
  }

  /**
   * sets the input hostname as being in a bootstrap/teardown process.
   */
  synchronized void setHostInProcess(String hostname) {
    if (!this.hostsInProcess.add(hostname)) {
      LOG.warn("Hostname " + hostname + "is being marked as being in a " +
          "bootstrap/teardown process, but it had previously been marked " +
          "already");
    }
  }

  /**
   * removes the input hostname from the set of hosts being in a
   * bootstrap/teardown process.
   */
  synchronized void unsetHostInProcess(String hostname) {
    if (!this.hostsInProcess.remove(hostname)) {
      LOG.warn("Hostname " + hostname + "is being marked as not being in a " +
          "bootstrap/teardown process, but it wasn't marked as being in such" +
          " a process");
    }
  }


  public synchronized void init() throws IOException {
    if (!bootStrapDir.exists()) {
      boolean mkdirs = bootStrapDir.mkdirs();
      if (!mkdirs) throw new IOException("Unable to make directory for " +
          "bootstrap " + bootStrapDir);
    }
  }

  private synchronized BSResponse runBsAction(
      SshHostInfo info, String actionScript) {
    BSResponse response = new BSResponse();
    /* Run some checks for ssh host */
    if (bsActionRunner != null) {
      response.setLog("BootStrap action in Progress: Cannot Run more than one " +
          "bootstrap action at the same time.");
      response.setStatus(BSRunStat.ERROR);
      return response;
    }
    for (String host : info.getHosts()) {
      if (this.hostsInProcess.contains(host)) {
        response.setStatus(BSRunStat.ERROR);
        response.setLog("Host " + host + "is already in a bootstrap or " +
            "teardown process. Please wait until the process is complete " +
            "before you start a bootstrap action on the host.");
        return response;
      }
    }

    requestId++;

    bsActionRunner = new BSActionRunner(this, info, bootStrapDir.toString(),
        bootstrapActionScript, actionScript, bootSetupAgentPassword, requestId,
        0L, this.masterHostname, info.isVerbose(), this.clusterOsType,
        this.projectVersion, this.serverPort);
    bsActionRunner.start();
    response.setStatus(BSRunStat.OK);
    response.setRequestId(requestId);
    return response;
  }

  public synchronized BSResponse runBootStrap(SshHostInfo info) {
    LOG.info("BootStrapping hosts " + info.hostsString());
    BSResponse response = runBsAction(info, bootSetupAgentScript);
    response.setLog("Running Bootstrap now.");
    return response;
  }

  public synchronized BSResponse runTeardown(SshHostInfo info) {
    LOG.info("Tearing down hosts " + info.hostsString());
    BSResponse response = runBsAction(info, teardownAgentScript);
    response.setLog("Running teardown now.");
    return response;
  }

  /**
   * @param hosts
   * @return
   */
  public synchronized List<BSHostStatus> getHostInfo(List<String> hosts) {
    List<BSHostStatus> statuses = new ArrayList<BSHostStatus>();

    if (null == hosts || 0 == hosts.size() || (hosts.size() == 1 && hosts.get(0).equals("*"))) {
      for (BootStrapRequest status : bsStatus.values()) {
        if (null != status.getHostsStatus())
          statuses.addAll(status.getHostsStatus());
      }
    } else {
      // TODO make bootstrapping a bit more robust then stop looping
      for (BootStrapRequest status : bsStatus.values()) {
        for (BSHostStatus hostStatus : status.getHostsStatus()) {
          if (-1 != hosts.indexOf(hostStatus.getHostName())) {
            statuses.add(hostStatus);
          }
        }
      }
    }

    return statuses;
  }

  /**
   *
   */
  public synchronized void resetBootstrapRunner() {
    bsActionRunner = null;
  }

}
