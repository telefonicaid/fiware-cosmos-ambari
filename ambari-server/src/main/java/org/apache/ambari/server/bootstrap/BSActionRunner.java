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
import java.util.LinkedList;
import java.util.List;
import java.util.concurrent.Executors;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.ScheduledFuture;
import java.util.concurrent.TimeUnit;

import org.apache.ambari.server.bootstrap.BootStrapRequest.BSStat;
import org.apache.commons.io.FileUtils;
import org.apache.commons.lang.StringUtils;
import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;

class BSActionRunner extends Thread {
  private static Log LOG = LogFactory.getLog(BSActionRunner.class);
  private static final String DEFAULT_USER = "root";

  private boolean finished = false;
  private final SshHostInfo sshHostInfo;
  private final File bootDir;
  private final String bsScript;
  private final File sshKeyFile;
  private final int requestId;
  private final File requestIdDir;
  private final String agentSetupScript;
  private final String agentSetupPassword;
  private final String ambariHostname;
  private final boolean verbose;
  private final BootStrapImpl bsImpl;
  private final String clusterOsType;
  private final String projectVersion;

  public BSActionRunner(BootStrapImpl impl, SshHostInfo sshHostInfo, String bootDir,
      String bsScript, String agentSetupScript, String agentSetupPassword,
      int requestId, String hostName, boolean isVerbose, String clusterOsType,
      String projectVersion)
  {
    this.requestId = requestId;
    this.sshHostInfo = sshHostInfo;
    this.bsScript = bsScript;
    this.bootDir = new File(bootDir);
    this.requestIdDir = new File(bootDir, Integer.toString(requestId));
    this.sshKeyFile = new File(this.requestIdDir, "sshKey");
    this.agentSetupScript = agentSetupScript;
    this.agentSetupPassword = agentSetupPassword;
    this.ambariHostname = hostName;
    this.verbose = isVerbose;
    this.clusterOsType = clusterOsType;
    this.projectVersion = projectVersion;
    this.bsImpl = impl;
    BootStrapRequest status = new BootStrapRequest();
    status.setLog("RUNNING");
    status.setStatus(BSStat.RUNNING);
    bsImpl.updateStatus(requestId, status);
  }

  /**
   * Update the gathered data from reading output
   */
  private class StatusCollector implements Runnable {
    @Override
    public void run() {
      BSHostStatusCollector collector = new BSHostStatusCollector(requestIdDir,
          sshHostInfo.getHosts());
      collector.run();
      List<BSHostStatus> hostStatus = collector.getHostStatus();
      BootStrapRequest status = new BootStrapRequest();
      status.setHostsStatus(hostStatus);
      status.setLog("");
      status.setStatus(BSStat.RUNNING);
      bsImpl.updateStatus(requestId, status);
    }
  }

  private String getCommand(String hostString, String user, File passwordFile) {
    List<String> command = new LinkedList<String> ();
    command.add(this.bsScript);
    command.add(hostString);
    command.add(this.requestIdDir.toString());
    command.add(user);
    command.add(this.sshKeyFile.toString());
    command.add(this.agentSetupScript);
    command.add(this.ambariHostname);
    command.add(this.clusterOsType);
    command.add(this.projectVersion);
    if (passwordFile != null) {
      command.add(passwordFile.toString());
    } else {
      command.add("null");
    }

    LOG.info(String.format("Host= %s bs=%s requestDir=%s user=%s keyfile=%s " +
        "passwordFile=%s server=%s version=%s", hostString, this.bsScript,
        requestIdDir, user, this.sshKeyFile, passwordFile, this.ambariHostname,
        projectVersion));

    return StringUtils.join(command, " ");
  }

  /** Create request id dir for each bootstrap call **/
  private void createRunDir() throws IOException {
    if (!bootDir.exists()) {
      // create the bootdir directory.
      if (! bootDir.mkdirs()) {
        throw new IOException("Cannot create " + bootDir);
      }
    }
    /* create the request id directory */
    if (requestIdDir.exists()) {
      /* delete the directory and make sure we start back */
      FileUtils.deleteDirectory(requestIdDir);
    }
    /* create the directory for the run dir */
    if (! requestIdDir.mkdirs()) {
      throw new IOException("Cannot create " + requestIdDir);
    }
  }

  private void writeSshKeyFile(String data) throws IOException {
    FileUtils.writeStringToFile(sshKeyFile, data);
  }

  private void writePasswordFile(File passwordFile, String data) throws IOException {
    FileUtils.writeStringToFile(passwordFile, data);
  }

  private void finished() {
    this.finished = true;
    for (String host : this.sshHostInfo.getHosts()) {
      this.bsImpl.unsetHostInProcess(host);
    }
  }

  private void init() {
    for (String host : this.sshHostInfo.getHosts()) {
      this.bsImpl.setHostInProcess(host);
    }
  }

  @Override
  public void run() {
    String user = sshHostInfo.getUser();
    if (user == null || user.isEmpty()) {
      user = DEFAULT_USER;
    }

    String shellCommand[] = new String[3];
    BSStat stat = BSStat.RUNNING;
    String scriptlog = "";
    File passwordFile = null;
    try {
      this.init();
      createRunDir();
      if (LOG.isDebugEnabled()) {
        // FIXME needs to be removed later
        // security hole
        LOG.debug("Using ssh key=\""
            + sshHostInfo.getSshKey() + "\"");
      }

      String password = sshHostInfo.getPassword();
      if (password != null && !password.isEmpty()) {
        passwordFile = new File(this.requestIdDir, "host_pass");
        // TODO : line separator should be changed
        // if we are going to support multi platform server-agent solution
        String lineSeparator = System.getProperty("line.separator");
        password = password + lineSeparator;
        writePasswordFile(passwordFile, password);
      }

      writeSshKeyFile(sshHostInfo.getSshKey());
      /* Running command:
       * script hostlist bsdir user sshkeyfile
       */
      shellCommand[0] = "sh";
      shellCommand[1] = "-c";

      String[] env = new String[] { "AMBARI_PASSPHRASE=" + agentSetupPassword };
      if (this.verbose)
        env = new String[] { env[0], " BS_VERBOSE=\"-vvv\" " };

      String commandString = this.getCommand(
          sshHostInfo.hostsString(), user, passwordFile);

      if (LOG.isDebugEnabled()) {
        LOG.debug(commandString);
      }

      String bootStrapOutputFile = requestIdDir + File.separator + "bootstrap.out";
      String bootStrapErrorFile = requestIdDir + File.separator + "bootstrap.err";
      commandString += " 1> " + bootStrapOutputFile + " 2>" + bootStrapErrorFile;

      shellCommand[2] = commandString;
      Process process = Runtime.getRuntime().exec(shellCommand, env);

      // Startup a scheduled executor service to look through the logs
      ScheduledExecutorService scheduler = Executors.newScheduledThreadPool(1);
      StatusCollector statusCollector = new StatusCollector();
      ScheduledFuture<?> handle = scheduler.scheduleWithFixedDelay(statusCollector,
          0, 10, TimeUnit.SECONDS);
      LOG.info("Kicking off the scheduler for polling on logs in " +
          this.requestIdDir);
      try {

        LOG.info("Bootstrap output, log="
              + bootStrapErrorFile + " " + bootStrapOutputFile);
        int exitCode = process.waitFor();
        String outMesg = "";
        String errMesg = "";
        try {
          outMesg = FileUtils.readFileToString(new File(bootStrapOutputFile));
          errMesg = FileUtils.readFileToString(new File(bootStrapErrorFile));
        } catch(IOException io) {
          LOG.info("Error in reading files ", io);
        }
        scriptlog = outMesg + "\n\n" + errMesg;
        LOG.info("Script log Mesg " + scriptlog);
        if (exitCode != 0) {
          stat = BSStat.ERROR;
        } else {
          stat = BSStat.SUCCESS;
        }

        scheduler.schedule(new StatusCollector(), 0, TimeUnit.SECONDS);
        long startTime = System.currentTimeMillis();
        while (true) {
          if (LOG.isDebugEnabled()) {
            LOG.debug("Waiting for hosts status to be updated");
          }
          boolean pendingHosts = false;
          BootStrapRequest tmpStatus = bsImpl.getStatus(requestId);
          for (BSHostStatus status : tmpStatus.getHostsStatus()) {
            if (status.getStatus().equals("RUNNING")) {
              pendingHosts = true;
            }
          }
          if (LOG.isDebugEnabled()) {
            LOG.debug("Whether hosts status yet to be updated, pending="
                + pendingHosts);
          }
          if (!pendingHosts) {
            break;
          }
          try {
            Thread.sleep(1000);
          } catch (InterruptedException e) {
            // continue
          }
          long now = System.currentTimeMillis();
          if (now >= (startTime+15000)) {
            LOG.warn("Gave up waiting for hosts status to be updated");
            break;
          }
        }
      } catch (InterruptedException e) {
        throw new IOException(e);
      } finally {
        handle.cancel(true);
        /* schedule a last update */
        scheduler.schedule(new StatusCollector(), 0, TimeUnit.SECONDS);
        scheduler.shutdownNow();
        try {
          scheduler.awaitTermination(10, TimeUnit.SECONDS);
        } catch (InterruptedException e) {
          LOG.info("Interruped while waiting for scheduler");
        }
        process.destroy();
      }
    } catch(IOException io) {
      LOG.info("Error executing bootstrap " + io.getMessage());
      stat = BSStat.ERROR;
    }
    finally {
      /* get the bstatus */
      BootStrapRequest tmpStatus = bsImpl.getStatus(requestId);
      for (BSHostStatus hostStatus : tmpStatus.getHostsStatus()) {
        if ("FAILED".equals(hostStatus.getStatus())) {
          stat = BSStat.ERROR;
          break;
        }
      }
      tmpStatus.setLog(scriptlog);
      tmpStatus.setStatus(stat);
      bsImpl.updateStatus(requestId, tmpStatus);
      bsImpl.resetBootstrapRunner();
      // Remove private ssh key after bootstrap is complete
      try {
        FileUtils.forceDelete(sshKeyFile);
      } catch (IOException io) {
        LOG.warn(io.getMessage());
      }
      if (passwordFile != null) {
        // Remove password file after bootstrap is complete
        try {
          FileUtils.forceDelete(passwordFile);
        } catch (IOException io) {
          LOG.warn(io.getMessage());
        }
      }
      finished();
    }
  }

  public synchronized boolean isRunning() {
    return !this.finished;
  }
}
