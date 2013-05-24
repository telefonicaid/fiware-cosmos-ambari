#!/usr/bin/env python

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

from SCP import SCP
from ParallelExecution import ParallelExecution


class PSCP:

    """Run SCP in parallel for a given list of hosts"""
    def __init__(self, hosts, user, ssh_key_file, inputfile, remote,
                 bootdir, timeout):
        self.runner = ParallelExecution(hosts, timeout)
        self.user = user
        self.ssh_key_file = ssh_key_file
        self.inputfile = inputfile
        self.remote = remote
        self.bootdir = bootdir

    def getstatus(self):
        return self.runner.getstatus()

    def create_scp_from_host(self, host):
        return SCP(self.user, self.ssh_key_file, host,
                   self.inputfile, self.remote, self.bootdir)

    def run(self):
        self.runner.run(self.create_scp_from_host)
