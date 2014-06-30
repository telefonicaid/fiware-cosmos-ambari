=====================================
How to create a custom Ambari service
=====================================

To have Ambari manage a custom service you'll need to make additions to these projects:

- ``ambari-server`` - define the service and its components
- ``ambari-agent``  - add the puppet code for deploying, configuring and starting the service

-------------
ambari-server
-------------

1. Define the service and its components in the software stack

   1.1. First choose the stack you wish to add the new service to. Stacks are found at::

    cosmos-ambari/ambari-server/src/main/resources/stacks/[STACK_NAME]/[STACK_VERSION]

    e.g.
    cosmos-ambari/ambari-server/src/main/resources/stacks/HDP/2.0.6_Cosmos

   1.2 Create a new folder for the service. It needs to be UPPER_CASE::

    e.g.
    cosmos-ambari/ambari-server/src/main/resources/stacks/HDP/2.0.6_Cosmos/services/YOUR_SERVICE

   1.3 Define the service components. Create a ``metainfo.xml`` inside your service folder.
   In ``cosmos-ambari/ambari-server/src/main/resources/stacks/HDP/2.0.6_Cosmos/services/YOUR_SERVICE/metainfo.xml``::

    <metainfo>
      <user>root</user>
      <comment>Your new service</comment>
      <version>0.1.0</version>

      <components>
        <component>
          <name>YOUR_MASTER_COMPONENT</name>
          <category>MASTER</category>
        </component>
        <component>
          <name>YOUR_SLAVE_COMPONENT</name>
          <category>SLAVE</category>
        </component>
        <component>
          <name>YOUR_SLAVE_COMPONENT</name>
          <category>SLAVE</category>
        </component>
        <component>
          <name>YOUR_CLIENT_COMPONENT</name>
          <category>CLIENT</category>
        </component>
      </components>
    </metainfo>

   ``MASTER`` and ``SLAVE`` tend to be services with daemon-like lifecycles (can be installed, started, stopped like an HDFS Namenode/Datanode) whereas ``CLIENT`` components only need to be installed (e.g. a tool like HDFS client)
2. Add the components in the list of roles ambari-server can manage. Edit the enum ``org.apache.ambari.server.Role`` and add the new components::

    public enum Role {
      ...
     YOUR_MASTER_COMPONENT,
     YOUR_SLAVE_COMPONENT,
     YOUR_CLIENT_COMPONENT
    }


------------
ambari-agent
------------

1. Add your puppet code to handle your service deployment

   1.1. Add a new puppet module under::

    cosmos-ambari/ambari-agent/src/main/puppet/modules/[your_service]

   1.2. Decide how to map the different service components to puppet.
   One way to do it is to have one puppet class for each component.
   In our example we can have::

    # in puppet/modules/[your_service]/manifests/master/init.pp
    class your_module::master($service_state) {}

    # in puppet/modules/[your_service]/manifests/slave/init.pp
    class your_module::slave($service_state) {}

    # in puppet/modules/[your_service]/manifests/client/init.pp
    class your_module::client($service_state) {}

   1.4. For each component class ensure the ``$service_state`` parameter is passed.
   Ambari manages 3 states that will be passed to your module depening on the service's lifecycle phase::

    installed_and_configured # download, install packages and configure them
    running                  # start the service
    stopped                  # stop the service

   1.5. Split your puppet code according to the Ambari lifecycle phases.
   For each component we tend to have at least 4 classes::

    init.pp     # the main class that we saw before
    package.pp  # responsible for installing the component packages
    config.pp   # reponsible for configuring the component packages
    service.pp  # responsible for starting the service if the component is a daemon

   The ``init.pp`` is reponsible for figuring out the component's lifecycle phase, as passed by Ambari, and delegate to the
   according class.
   To do that you can use the ``$service_state`` value to decide which part of the puppet code to execute. An example of ``init.pp``::

    class your_service::master($service_state) {
      case $service_state {
        'installed_and_configured' : {
          include your_service::package, your_service::config
          anchor {'your_service::master::begin' :}
            -> Class['your_service::master::package']
            -> Class['your_service::master::config']
            -> anchor {'your_service::master::end': }
        }
        'running', 'stopped' :       {
          class { 'your_service::master::service':
            service_state => $service_state
          }
          anchor {'your_service::master::begin' :}
            -> Class['your_service::master::service']
            -> anchor {'your_service::master::end': }
        }
      }
    }

2. Map the new puppet module to the Ambari-managed components. In ``ambari-agent/src/main/python/ambari_agent/AmbariConfig.py``:

   2.1. Import the new puppet code. Add the new puppet files in the list ``imports``::

    imports = [
      ...
      "your_service/manifests/master/*.pp",
      "your_service/manifests/slave/*.pp",
      "your_service/manifests/client/*.pp"
    ]

   2.2. Map the component roles to the puppet classes. In the hash ``rolesToClass``::

    rolesToClass = {
      ...
      'YOUR_MASTER_COMPONENT': 'your_service::master',
      'YOUR_SLAVE_COMPONENT': 'your_service::slave',
      'YOUR_CLIENT_COMPONENT': 'your_service::client'
    }

3. If the service does not contribute to the cluster's global configuration then Ambari needs to know.
   Edit ``ambari-agentsrc/main/python/ambari_agent/manifestGenerator.py`` and in the list ``non_global_configuration_types``
   add the puppet module name for your service::

    non_global_configuration_types = [
       ...
       "your_service"
    ]
