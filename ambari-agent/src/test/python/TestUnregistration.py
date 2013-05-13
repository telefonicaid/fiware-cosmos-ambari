#!/usr/bin/env python2.6

'''
Licensed to the Apache Software Foundation (ASF) under one
or more contributor license agreements.  See the NOTICE file
distributed with this work for additional information
regarding copyright ownership.  The ASF licenses this file
to you under the Apache License, Version 2.0 (the
"License"); you may not use this file except in compliance
with the License.  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
'''

from unittest import TestCase
import os
import tempfile

from ambari_agent.Unregister import Unregister
from ambari_agent.AmbariConfig import AmbariConfig


class TestUnegistration(TestCase):

  def test_unregistration_build(self):
    config = AmbariConfig().getConfig()
    tmpdir = tempfile.gettempdir()
    config.set('agent', 'prefix', tmpdir)

    ver_file = os.path.join(tmpdir, "version")
    with open(ver_file, "w") as text_file:
      text_file.write("1.3.0")

    register = Unregister(config)
    data = register.build(1)
    self.assertEquals(data['hostname'] != "", True, "hostname should not be empty")
    self.assertEquals(data['responseId'], 1)
    self.assertEquals(data['timestamp'] > 1353678475465L, True, "timestamp should not be empty")
    self.assertEquals(data['agentVersion'], '1.3.0', "agentVersion should not be empty")
    self.assertEquals(len(data), 4)

    os.remove(ver_file)