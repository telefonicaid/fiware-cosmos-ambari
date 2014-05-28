=====================
Cosmos fork of Ambari
=====================

This is the private fork of Ambari maintained by Cosmos to apply a (small) set of patches to the vanilla distribution.

You can check the differences between cosmos-ambari and the original ambari repo by using git diff::

    git remote add ambari https://github.com/apache/ambari
    git fetch ambari
    git diff origin/<branch> ambari/trunk

----------
Build RPMs
----------

From the project root::

    mvn -B clean install package rpm:rpm -DskipTests -Dpython.ver="python >= 2.6" -Preplaceurl

------------------------------
Create a custom Ambari service
------------------------------

For a guide see `CUSTOM_AMBARI_SERVICE.rst <CUSTOM_AMBARI_SERVICE.rst>`_
