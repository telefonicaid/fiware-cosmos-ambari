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

import socket
import time
import sys
import logging
import pprint
import os
import subprocess
import threading
import traceback
from pprint import pformat

DEBUG=False

class SCP(threading.Thread):

    """ SCP implementation that is thread based. The status can be returned using
     status val """
    def __init__(self, user, sshkey_file, host, inputFile, remote, bootdir, host_log):
        self.user = user
        self.sshkey_file = sshkey_file
        self.host = host
        self.inputFile = inputFile
        self.remote = remote
        self.bootdir = bootdir
        self.host_log = host_log
        pass

    def run(self):
        scpcommand = ["scp",
                      "-o", "ConnectTimeout=60",
                      "-o", "BatchMode=yes",
                      "-o", "StrictHostKeyChecking=no",
                      "-i", self.sshkey_file, self.inputFile, self.user + "@" +
                      self.host + ":" + self.remote]
        if DEBUG:
            self.host_log.write("Running scp command " + ' '.join(scpcommand))
        scpstat = subprocess.Popen(scpcommand, stdout=subprocess.PIPE,
                                   stderr=subprocess.PIPE)
        log = scpstat.communicate()
        log = "STDOUT\n" + log[0] + "\nSTDERR\n" + log[1]
        self.host_log.write(log)
        self.host_log.write("scp " + self.inputFile + " done for host " + self.host +
                 ", exitcode=" + str(scpstat.returncode))
        return scpstat.returncode
