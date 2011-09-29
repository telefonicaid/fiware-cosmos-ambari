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
package org.apache.ambari.controller.rest.resources;

import java.util.ArrayList;
import java.util.List;

import javax.ws.rs.Consumes;
import javax.ws.rs.DefaultValue;
import javax.ws.rs.GET;
import javax.ws.rs.POST;
import javax.ws.rs.PUT;
import javax.ws.rs.Path;
import javax.ws.rs.PathParam;
import javax.ws.rs.Produces;
import javax.ws.rs.QueryParam;
import javax.ws.rs.WebApplicationException;
import javax.ws.rs.core.Response;
import javax.xml.bind.annotation.XmlElement;

import org.apache.ambari.common.rest.entities.Blueprint;
import org.apache.ambari.common.rest.entities.Cluster;
import org.apache.ambari.common.rest.entities.Stack;
import org.apache.ambari.controller.Clusters;
import org.apache.ambari.controller.Stacks;

import com.sun.jersey.spi.container.WebApplication;
import com.sun.jersey.spi.resource.Singleton;

/** Stacks resource represents a collection of Hadoop Stacks
 */
@Path(value = "/stacks")
public class StacksResource {       
    
    /** Import a new Hadoop Stack description
     *  <p>
     *  Specific revision of stack is imported/created into Ambari, if not already present. It returns the 
     *  description of the stack if imported successfully. If 
     *  <p>
     *  REST:<br>
     *  &nbsp;&nbsp;&nbsp;&nbsp;URL Path                                    : /stacks/<br>
     *  &nbsp;&nbsp;&nbsp;&nbsp;HTTP Method                                 : POST <br>
     *  &nbsp;&nbsp;&nbsp;&nbsp;HTTP Request Header                         : <br>
     *  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Content-type        = application/json <br>
     *  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Accept              = application/json <br>
     *  &nbsp;&nbsp;&nbsp;&nbsp;HTTP Response Header                        : <br>
     *  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Content-type        = application/json <br>
     *  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Accept              = application/json <br>
     *  <p> 
     * 
     * @param   url Location of the new stack definition
     * @throws  Exception               throws Exception
     */
    @POST
    @Consumes({"application/json", "application/xml"})
    public Stack importStackDescription(@DefaultValue("") @QueryParam("url") String url) throws WebApplicationException {       
        try {
            return Stacks.getInstance().importStackDescription(url);
        }catch (WebApplicationException we) {
            throw we;
        }catch (Exception e) {
            throw new WebApplicationException(e, Response.Status.INTERNAL_SERVER_ERROR);
        }
    }
    
    /** Get the list of stacks installed with Ambari controller.
     * 
     *  <p>
     *  REST:<br>
     *  &nbsp;&nbsp;&nbsp;&nbsp;URL Path                                    : /stacks/{stackName}<br>
     *  &nbsp;&nbsp;&nbsp;&nbsp;HTTP Method                                 : POST <br>
     *  &nbsp;&nbsp;&nbsp;&nbsp;HTTP Request Header                         : <br>
     *  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Content-type        = application/json <br>
     *  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Accept              = application/json <br>
     *  &nbsp;&nbsp;&nbsp;&nbsp;HTTP Response Header                        : <br>
     *  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Content-type        = application/json <br>
     *  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Accept              = application/json <br>
     *  <p> 
     * 
     * @param searchToken       Optionally specify the search token to return the stacks where stack name includes the search token 
     * @return                  Returns list of stack definitions
     * @throws Exception        throws Exception
     */
    @GET
    @Consumes({"application/json", "application/xml"})
    public List<String> getStackList (@DefaultValue("") @QueryParam("search") String searchToken) throws Exception {
        
        try {
            List <String> list = Stacks.getInstance().getStackList();
            if (list.isEmpty()) {
                throw new WebApplicationException (Response.Status.NO_CONTENT);
            }
            return list;
        }catch (WebApplicationException we) {
            throw we;
        }catch (Exception e) {
            throw new WebApplicationException(e, Response.Status.INTERNAL_SERVER_ERROR);
        } 
    }

    /** Get the stack definition
     * 
     *  <p>
     *  REST:<br>
     *  &nbsp;&nbsp;&nbsp;&nbsp;URL Path                                    : /stacks/{stackName}<br>
     *  &nbsp;&nbsp;&nbsp;&nbsp;HTTP Method                                 : GET <br>
     *  &nbsp;&nbsp;&nbsp;&nbsp;HTTP Request Header                         : <br>
     *  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Content-type        = application/json <br>
     *  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Accept              = application/json <br>
     *  &nbsp;&nbsp;&nbsp;&nbsp;HTTP Response Header                        : <br>
     *  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Content-type        = application/json <br>
     *  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Accept              = application/json <br>
     *  <p> 
     * 
     * @param stackName         The name of the stack to get the default blueprint
     * @return                  The default blueprint for that stack
     * @throws Exception        throws Exception
     */
    @Path(value = "/{stackName}")
    @GET
    @Produces({"application/json", "application/xml"})
    public Stack getStackDefinition(@PathParam("stackName") String stackName,
                     @DefaultValue("") @QueryParam("revision") String revision) throws Exception {  
        try {
            if (revision == null || revision.equals("")) {
                Exception e = new Exception ("Revision number not specified");
                throw new WebApplicationException (e, Response.Status.BAD_REQUEST);
            }
            return Stacks.getInstance().getStack(stackName, Integer.parseInt(revision));
        }catch (WebApplicationException we) {
            throw we;
        }catch (Exception e) {
            throw new WebApplicationException(e, Response.Status.INTERNAL_SERVER_ERROR);
        }      
    }
    
    /** Get the default blueprint for a particular stack
     * 
     *  <p>
     *  REST:<br>
     *  &nbsp;&nbsp;&nbsp;&nbsp;URL Path                                    : /stacks/{stackName}/default-blueprint<br>
     *  &nbsp;&nbsp;&nbsp;&nbsp;HTTP Method                                 : GET <br>
     *  &nbsp;&nbsp;&nbsp;&nbsp;HTTP Request Header                         : <br>
     *  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Content-type        = application/json <br>
     *  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Accept              = application/json <br>
     *  &nbsp;&nbsp;&nbsp;&nbsp;HTTP Response Header                        : <br>
     *  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Content-type        = application/json <br>
     *  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Accept              = application/json <br>
     *  <p> 
     * 
     * @param stackName         The name of the stack to get the default blueprint
     * @return                  The default blueprint for that stack
     * @throws Exception        throws Exception
     */
    @Path(value = "/{stackName}/default-blueprint")
    @GET
    @Produces({"application/json", "application/xml"})
    public Blueprint getDefaultBlueprint(@PathParam("stackName") String stackName,
                     @DefaultValue("") @QueryParam("revision") String revision) throws Exception {
        try {
            if (revision == null || revision.equals("")) {
                Exception e = new Exception ("Revision number not specified");
                throw new WebApplicationException (e, Response.Status.BAD_REQUEST);
            }
            return Stacks.getInstance().getDefaultBlueprint(stackName, Integer.parseInt(revision));
        }catch (WebApplicationException we) {
            throw we;
        }catch (Exception e) {
            throw new WebApplicationException(e, Response.Status.INTERNAL_SERVER_ERROR);
        }     
    }
}