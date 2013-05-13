package org.apache.ambari.server.agent;

import org.codehaus.jackson.annotate.JsonProperty;

/**
 * Data model for Ambari Agent to send unregistration request to Ambari Controller.
 */
public class Unregister {
  private int responseId = -1;
  private long timestamp;
  private String hostname;
  private String agentVersion;

  @JsonProperty("responseId")
  public int getResponseId() {
    return responseId;
  }

  @JsonProperty("responseId")
  public void setResponseId(int responseId) {
    this.responseId = responseId;
  }

  public long getTimestamp() {
    return timestamp;
  }

  public String getHostname() {
    return hostname;
  }

  public void setHostname(String hostname) {
    this.hostname = hostname;
  }

  public void setTimestamp(long timestamp) {
    this.timestamp = timestamp;
  }

  public String getAgentVersion() {
    return agentVersion;
  }

  public void setAgentVersion(String agentVersion) {
    this.agentVersion = agentVersion;
  }

  @Override
  public String toString() {
    String ret = "responseId=" + responseId + "\n" +
        "timestamp=" + timestamp + "\n" +
        "hostname=" + hostname + "\n";
    return ret;
  }
}
