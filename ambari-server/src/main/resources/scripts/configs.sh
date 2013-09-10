#!/bin/bash
#
# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.
#

usage () {
  echo "Usage: configs.sh <ACTION> <AMBARI_HOST> <CLUSTER_NAME> <SITE_NAME> [CONFIG_KEY] [CONFIG_VALUE]";
  echo "";
  echo "       <ACTION>: One of 'get', 'set', 'delete'. 'Set' adds/updates as necessary.";
  echo "       <AMBARI_HOST>: Server external host name";
  echo "       <CLUSTER_NAME>: Name given to cluster. Ex: 'c1'"
  echo "       <SITE_NAME>: One of the various configuration sites in Ambari. Ex:global, core-site, hdfs-site, etc.";
  echo "       [CONFIG_KEY]: Key that has to be set or deleted. Not necessary for 'get' action.";
  echo "       [CONFIG_VALUE]: Optional value to be set. Not necessary for 'get' or 'delete' actions.";
  exit 1;
}

AMBARIURL="http://$2:8080"
USERID="admin"
PASSWD="admin"
CLUSTER=$3
SITE=$4
SITETAG=''
CONFIGKEY=$5
CONFIGVALUE=$6

###################
## currentSiteTag()
###################
currentSiteTag () {
  currentSiteTag=''
  found=''
  #currentSite=`cat ds.json | grep -E "$SITE|tag"`; 
  currentSite=`curl -s -u $USERID:$PASSWD "$AMBARIURL/api/v1/clusters/$CLUSTER?fields=Clusters/desired_configs" | grep -E "$SITE|tag"`;
  for line in $currentSite; do
    if [ $line != "{" -a $line != ":" -a $line != '"tag"' ] ; then
      if [ -n "$found" -a -z "$currentSiteTag" ]; then
        currentSiteTag=$line;
      fi
      if [ $line == "\"$SITE\"" ]; then
        found=$SITE; 
      fi
    fi
  done;
  if [ -z $currentSiteTag ]; then
    echo "Tag unknown for site $SITE";
    exit 1;
  fi
  currentSiteTag=`echo $currentSiteTag|cut -d \" -f 2`
  SITETAG=$currentSiteTag;
}

#############################################
## doConfigUpdate() MODE = 'set' | 'delete'
#############################################
doConfigUpdate () {
  MODE=$1
  currentSiteTag
  echo "########## Performing '$MODE' $CONFIGKEY:$CONFIGVALUE on (Site:$SITE, Tag:$SITETAG)";
  propertiesStarted=0;
  curl -s -u $USERID:$PASSWD "$AMBARIURL/api/v1/clusters/$CLUSTER/configurations?type=$SITE&tag=$SITETAG" | while read -r line; do
    ## echo ">>> $line";
    if [ "$propertiesStarted" -eq 0 -a "`echo $line | grep "\"properties\""`" ]; then
      propertiesStarted=1
    fi;
    if [ "$propertiesStarted" -eq 1 ]; then
      if [ "$line" == "}" ]; then
        ## Properties ended
        ## Add property
        if [ "$MODE" == "set" ]; then
          newProperties="$newProperties, \"$CONFIGKEY\" : \"$CONFIGVALUE\" ";
        elif [ "$MODE" == "delete" ]; then
          # Remove the last ,
          propLen=${#newProperties}
          lastChar=${newProperties:$propLen-1:1}
          if [ "$lastChar" == "," ]; then
            newProperties=${newProperties:0:$propLen-1}
          fi
        fi
        newProperties=$newProperties$line
        propertiesStarted=0;
        
        newTag=`date "+%Y%m%d%H%M%S"`
        newTag="version$newTag"
        finalJson="{ \"Clusters\": { \"desired_config\": {\"type\": \"$SITE\", \"tag\":\"$newTag\", $newProperties}}}"
        newFile="doSet_$newTag.json"
        echo "########## PUTting json into: $newFile"
        echo $finalJson > $newFile
        curl -u $USERID:$PASSWD -X PUT "$AMBARIURL/api/v1/clusters/$CLUSTER" --data @$newFile
        currentSiteTag
        echo "########## NEW Site:$SITE, Tag:$SITETAG";
      elif [ "`echo $line | grep "\"$CONFIGKEY\""`" ]; then
        echo "########## Config found. Skipping origin value"
      else
        newProperties=$newProperties$line
      fi
    fi
  done;
}

#############################################
## doGet()
#############################################
doGet () {
  currentSiteTag
  echo "########## Performing 'GET' on (Site:$SITE, Tag:$SITETAG)";
  propertiesStarted=0;
  curl -s -u $USERID:$PASSWD "$AMBARIURL/api/v1/clusters/$CLUSTER/configurations?type=$SITE&tag=$SITETAG" | while read -r line; do
    ## echo ">>> $line";
    if [ "$propertiesStarted" -eq 0 -a "`echo $line | grep "\"properties\""`" ]; then
      propertiesStarted=1
    fi;
    if [ "$propertiesStarted" -eq 1 ]; then
      if [ "$line" == "}" ]; then
        ## Properties ended
        propertiesStarted=0;
      fi
      echo $line
    fi
  done;
}

case "$1" in
  set)
    if (($# != 6)); then
      usage
    fi
    doConfigUpdate "set"
    ;;
  get)
    if (($# != 4)); then
      usage
    fi
    doGet
    ;;
  delete)
    if (($# != 5)); then
      usage
    fi
    doConfigUpdate "delete"
    ;;
  *) 
    usage
    ;;
esac