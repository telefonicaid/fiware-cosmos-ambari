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

import time

class ParallelExecution:

    """Run a command in parallel for a given list of hosts"""
    def __init__(self, hosts, timeout):
        self.hosts = hosts
        self.timeout = timeout
        self.ret = {}

    def splitlist(self, hosts, chunk_size):
        return [hosts[i:i + chunk_size]
                    for i in range(0, len(hosts), chunk_size)]

    def getstatus(self):
        return self.ret

    def run(self, command):
        """ Run 20 at a time in parallel """
        for chunk in self.splitlist(self.hosts, 20):
            chunkstats = []
            for host in chunk:
                thread = command(host)
                thread.start()
                chunkstats.append(thread)
            # wait for the threads to complete
            starttime = time.time()
            for chunkstat in chunkstats:
                elapsedtime = time.time() - starttime
                if elapsedtime < self.timeout:
                    timeout = self.timeout - elapsedtime
                else:
                    timeout = 0.0
                chunkstat.join(timeout)
                self.ret[chunkstat.getHost()] = chunkstat.getStatus()
