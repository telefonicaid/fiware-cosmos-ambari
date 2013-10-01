package org.apache.ambari.server.agent;

import org.codehaus.jackson.annotate.JsonProperty;

/**
 * Controller to Agent response data model.
 */
public class UnregistrationResponse {
  @JsonProperty("response")
  private RequestStatus response;

  //Response id to start with, usually zero.
  @JsonProperty("responseId")
  private long responseId;

  @JsonProperty("errorMessage")
  private String errorMessage = "";

  public RequestStatus getResponseStatus() {
    return response;
  }

  public void setResponseStatus(RequestStatus response) {
    this.response = response;
  }

  public long getResponseId() {
    return responseId;
  }

  public void setResponseId(long responseId) {
    this.responseId = responseId;
  }

  public void setErrorMessage(String errorMessage) {
    this.errorMessage = errorMessage;
  }

  public String getErrorMessage() {
    return this.errorMessage;
  }

  @Override
  public String toString() {
    return "RegistrationResponse{" +
        "response=" + response +
        ", responseId=" + responseId +
        ", errorMessage=" + errorMessage +
        '}';
  }
}
