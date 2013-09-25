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

class SSH(threading.Thread):

    """ Ssh implementation of this """
    def __init__(self, user, sshkey_file, host, command, bootdir, host_log, errorMessage=None):
        self.user = user
        self.sshkey_file = sshkey_file
        self.host = host
        self.command = command
        self.bootdir = bootdir
        self.errorMessage = errorMessage
        self.host_log = host_log
        pass

    def run(self):
        sshcommand = ["ssh",
                      "-o", "ConnectTimeOut=60",
                      "-o", "StrictHostKeyChecking=no",
                      "-o", "BatchMode=yes",
                      "-tt",
                      # Should prevent "tput: No value for $TERM and no -T
                      # specified" warning
                      "-i", self.sshkey_file,
                      self.user + "@" + self.host, self.command]
        if DEBUG:
            self.host_log.write("Running ssh command " + ' '.join(sshcommand))
        sshstat = subprocess.Popen(sshcommand, stdout=subprocess.PIPE,
                                   stderr=subprocess.PIPE)
        log = sshstat.communicate()
        errorMsg = log[1]
        if self.errorMessage and sshstat.returncode != 0:
            errorMsg = self.errorMessage + "\n" + errorMsg
        log = "STDOUT\n" + log[0] + "\nSTDERR\n" + errorMsg
        logFilePath = os.path.join(self.bootdir, self.host + ".log")
        self.host_log.write(log)

        self.host_log.write("SSH command execution finished for host " + self.host +
                 ", exitcode=" + str(sshstat.returncode))
        return sshstat.returncode
