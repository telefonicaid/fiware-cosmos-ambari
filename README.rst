=====================
Cosmos fork of Ambari
=====================

This is the private fork of Ambari maintained by Cosmos to apply a (small) set of patches to the vanilla distribution.


Build RPMs
==========

From the project root::

    mvn -B clean install package rpm:rpm -DskipTests -Dpython.ver="python >= 2.6" -Preplaceurl
