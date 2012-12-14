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

package org.apache.ambari.server.controller.internal;

import java.util.Collections;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

import org.apache.ambari.server.AmbariException;
import org.apache.ambari.server.controller.AmbariManagementController;
import org.apache.ambari.server.controller.RequestStatusResponse;
import org.apache.ambari.server.controller.predicate.BasePredicate;
import org.apache.ambari.server.controller.spi.Predicate;
import org.apache.ambari.server.controller.spi.Request;
import org.apache.ambari.server.controller.spi.RequestStatus;
import org.apache.ambari.server.controller.spi.Resource;
import org.apache.ambari.server.controller.spi.ResourceProvider;
import org.apache.ambari.server.controller.spi.UnsupportedPropertyException;
import org.apache.ambari.server.controller.utilities.PredicateHelper;
import org.apache.ambari.server.controller.utilities.PropertyHelper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Basic resource provider implementation that maps to a management controller.
 */
public abstract class ResourceProviderImpl implements ResourceProvider, ObservableResourceProvider {

  /**
   * The set of property ids supported by this resource provider.
   */
  private final Set<String> propertyIds;

  /**
   * The management controller to delegate to.
   */
  private final AmbariManagementController managementController;

  /**
   * Key property mapping by resource type.
   */
  private final Map<Resource.Type, String> keyPropertyIds;

  /**
   * Observers of this observable resource provider.
   */
  private final Set<ResourceProviderObserver> observers = new HashSet<ResourceProviderObserver>();


  protected final static Logger LOG =
      LoggerFactory.getLogger(ResourceProviderImpl.class);

    // ----- Constructors ------------------------------------------------------
  /**
   * Create a  new resource provider for the given management controller.
   *
   * @param propertyIds           the property ids
   * @param keyPropertyIds        the key property ids
   * @param managementController  the management controller
   */
  protected ResourceProviderImpl(Set<String> propertyIds,
                               Map<Resource.Type, String> keyPropertyIds,
                               AmbariManagementController managementController) {
    this.propertyIds          = propertyIds;
    this.keyPropertyIds       = keyPropertyIds;
    this.managementController = managementController;
  }


  // ----- ResourceProvider --------------------------------------------------

  @Override
  public Set<String> getPropertyIds() {
    return propertyIds;
  }

  @Override
  public Map<Resource.Type, String> getKeyPropertyIds() {
    return keyPropertyIds;
  }


  // ----- ObservableResourceProvider ----------------------------------------

  @Override
  public void updateObservers(ResourceProviderEvent event) {
    for (ResourceProviderObserver observer : observers) {
      observer.update(event);
    }
  }

  @Override
  public void addObserver(ResourceProviderObserver observer) {
    observers.add(observer);
  }


  // ----- accessors ---------------------------------------------------------

  /**
   * Get the associated management controller.
   *
   * @return the associated management controller
   */
  public AmbariManagementController getManagementController() {
    return managementController;
  }


  // ----- utility methods ---------------------------------------------------

  /**
   * Get the set of property ids that uniquely identify the resources
   * of this provider.
   *
   * @return the set of primary key properties
   */
  protected abstract Set<String> getPKPropertyIds();

  /**
   * Notify all listeners of a creation event.
   *
   * @param type     the type of the resources being created
   * @param request  the request used to create the resources
   */
  protected void notifyCreate(Resource.Type type, Request request) {
    updateObservers(new ResourceProviderEvent(type, ResourceProviderEvent.Type.Create, request, null));
  }

  /**
   * Notify all listeners of a update event.
   *
   * @param type       the type of the resources being updated
   * @param request    the request used to update the resources
   * @param predicate  the predicate used to update the resources
   */
  protected void notifyUpdate(Resource.Type type, Request request, Predicate predicate) {
    updateObservers(new ResourceProviderEvent(type, ResourceProviderEvent.Type.Update, request, predicate));
  }

  /**
   * Notify all listeners of a delete event.
   *
   * @param type       the type of the resources being deleted
   * @param predicate  the predicate used to delete the resources
   */
  protected void notifyDelete(Resource.Type type, Predicate predicate) {
    updateObservers(new ResourceProviderEvent(type, ResourceProviderEvent.Type.Delete, null, predicate));
  }

  /**
   * Get a set of properties from the given property map and predicate.
   *
   * @param requestPropertyMap  the request properties (for update)
   * @param predicate           the predicate
   *
   * @return the set of properties used to build request objects
   */
  protected Set<Map<String, Object>> getPropertyMaps(Map<String, Object> requestPropertyMap,
                                                         Predicate predicate)
      throws AmbariException, UnsupportedPropertyException {

    SimplifyingPredicateVisitor visitor = new SimplifyingPredicateVisitor(propertyIds);
    PredicateHelper.visit(predicate, visitor);
    List<BasePredicate> predicates = visitor.getSimplifiedPredicates();

    if (predicates == null) {
      return _getPropertyMaps(requestPropertyMap, predicate);
    }

    Set<Map<String, Object>> properties = new HashSet<Map<String, Object>>();
    for (BasePredicate basePredicate : predicates) {
      properties.addAll(_getPropertyMaps(requestPropertyMap, basePredicate));
    }
    return properties;
  }

  private Set<Map<String, Object>> _getPropertyMaps(Map<String, Object> requestPropertyMap,
                                                         Predicate predicate)
      throws AmbariException, UnsupportedPropertyException {

    Set<String>              pkPropertyIds       = getPKPropertyIds();
    Set<Map<String, Object>> properties          = new HashSet<Map<String, Object>>();
    Set<Map<String, Object>> predicateProperties = new HashSet<Map<String, Object>>();

    if (requestPropertyMap == null || pkPropertyIds.equals(PredicateHelper.getPropertyIds(predicate))) {
      predicateProperties.add(getProperties(predicate));
    }
    else {
      for (Resource resource : getResources(PropertyHelper.getReadRequest(pkPropertyIds), predicate)) {
        predicateProperties.add(PropertyHelper.getProperties(resource));
      }
    }

    for (Map<String, Object> predicatePropertyMap : predicateProperties) {
      Map<String, Object> propertyMap = new HashMap<String, Object>(predicatePropertyMap);
      if (requestPropertyMap != null) {
        propertyMap.putAll(requestPropertyMap);
      }
      properties.add(propertyMap);
    }
    return properties;
  }

  /**
   * Check the properties of the request to make sure that they are supported by this
   * resource provider.
   *
   * @param type     the resource type
   * @param request  the update / create request
   *
   * @throws UnsupportedPropertyException thrown if the request contains one or more
   *                                      unsupported properties
   */
  protected void checkRequestProperties(Resource.Type type, Request request)
      throws UnsupportedPropertyException {

    //TODO : config messes this up for service resource, etc ...

//    Set<String> unsupportedPropertyIds = new HashSet<String>();
//
//    for (Map<String, Object> requestProperties : request.getProperties()) {
//      if (!propertyIds.containsAll(requestProperties.keySet())) {
//        Set<String> requestPropertyIds = new HashSet<String>(requestProperties.keySet());
//        requestPropertyIds.removeAll(propertyIds);
//        unsupportedPropertyIds.addAll(requestPropertyIds);
//      }
//    }
//
//    if (!unsupportedPropertyIds.isEmpty()) {
//      throw new UnsupportedPropertyException(type, unsupportedPropertyIds);
//    }
  }

  /**
   * Get a request status
   *
   * @return the request status
   */
  protected RequestStatus getRequestStatus(RequestStatusResponse response) {

    if (response != null){
      Resource requestResource = new ResourceImpl(Resource.Type.Request);
      requestResource.setProperty(PropertyHelper.getPropertyId("Requests", "id"), response.getRequestId());
      // TODO : how do we tell what a request status is?
      // for now make everything InProgress
      requestResource.setProperty(PropertyHelper.getPropertyId("Requests", "status"), "InProgress");
      return new RequestStatusImpl(requestResource);
    }
    return new RequestStatusImpl(null);
  }

  /**
   * Get a map of property values from a given predicate.
   *
   * @param predicate  the predicate
   *
   * @return the map of properties
   */
  protected static Map<String, Object> getProperties(Predicate predicate) {
    if (predicate == null) {
      return Collections.emptyMap();
    }
    PropertyPredicateVisitor visitor = new PropertyPredicateVisitor();
    PredicateHelper.visit(predicate, visitor);
    return visitor.getProperties();
  }

  /**
   * Set a property value on the given resource for the given id and value.
   * Make sure that the id is in the given set of requested ids.
   *
   * @param resource      the resource
   * @param propertyId    the property id
   * @param value         the value to set
   * @param requestedIds  the requested set of property ids
   */
  protected static void setResourceProperty(Resource resource, String propertyId, Object value, Set<String> requestedIds) {
    if (requestedIds.contains(propertyId)) {
      if (LOG.isDebugEnabled()) {
        LOG.debug("Setting property for resource"
            + ", resourceType=" + resource.getType()
            + ", propertyId=" + propertyId
            + ", value=" + value);
      }
      resource.setProperty(propertyId, value);
    }
    else {
      if (LOG.isDebugEnabled()) {
        LOG.debug("Skipping property for resource as not in requestedIds"
            + ", resourceType=" + resource.getType()
            + ", propertyId=" + propertyId
            + ", value=" + value);
      }
    }
  }

  /**
   * Factory method for obtaining a resource provider based on a given type and management controller.
   *
   *
   * @param type                  the resource type
   * @param propertyIds           the property ids
   * @param managementController  the management controller
   *
   * @return a new resource provider
   */
  public static ResourceProvider getResourceProvider(Resource.Type type,
                                                     Set<String> propertyIds,
                                                     Map<Resource.Type, String> keyPropertyIds,
                                                     AmbariManagementController managementController) {
    switch (type) {
      case Cluster:
        return new ClusterResourceProvider(propertyIds, keyPropertyIds, managementController);
      case Service:
        return new ServiceResourceProvider(propertyIds, keyPropertyIds, managementController);
      case Component:
        return new ComponentResourceProvider(propertyIds, keyPropertyIds, managementController);
      case Host:
        return new HostResourceProvider(propertyIds, keyPropertyIds, managementController);
      case HostComponent:
        return new HostComponentResourceProvider(propertyIds, keyPropertyIds, managementController);
      case Configuration:
        return new ConfigurationResourceProvider(propertyIds, keyPropertyIds, managementController);
      case Action:
        return new ActionResourceProvider(propertyIds, keyPropertyIds, managementController);
      case Request:
        return new RequestResourceProvider(propertyIds, keyPropertyIds, managementController);
      case Task:
        return new TaskResourceProvider(propertyIds, keyPropertyIds, managementController);
      case User:
        return new UserResourceProvider(propertyIds, keyPropertyIds, managementController);
      default:
        throw new IllegalArgumentException("Unknown type " + type);
    }
  }
}