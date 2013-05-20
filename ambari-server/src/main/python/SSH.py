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


class SSH(threading.Thread):

    """ Ssh implementation of this """
    def __init__(self, user, sshKeyFile, host, command, bootdir, errorMessage=None):
        self.user = user
        self.sshKeyFile = sshKeyFile
        self.host = host
        self.command = command
        self.bootdir = bootdir
        self.errorMessage = errorMessage
        self.ret = {"exitstatus": -1, "log": "FAILED"}
        threading.Thread.__init__(self)
        self.daemon = True
        pass

    def getHost(self):
        return self.host

    def getStatus(self):
        return self.ret

    def run(self):
        sshcommand = ["ssh",
                      "-o", "ConnectTimeOut=60",
                      "-o", "StrictHostKeyChecking=no",
                      "-o", "BatchMode=yes",
                      "-tt",
                      # Should prevent "tput: No value for $TERM and no -T
                      # specified" warning
                      "-i", self.sshKeyFile,
                      self.user + "@" + self.host, self.command]
        logging.info("Running ssh command " + ' '.join(sshcommand))
        sshstat = subprocess.Popen(sshcommand, stdout=subprocess.PIPE,
                                   stderr=subprocess.PIPE)
        log = sshstat.communicate()
        self.ret["exitstatus"] = sshstat.returncode
        errorMsg = log[1]
        if self.errorMessage and sshstat.returncode != 0:
            errorMsg = self.errorMessage + "\n" + errorMsg
        self.ret["log"] = "STDOUT\n" + log[0] + "\nSTDERR\n" + errorMsg
        logFilePath = os.path.join(self.bootdir, self.host + ".log")
        self.writeLogToFile(logFilePath)

        doneFilePath = os.path.join(self.bootdir, self.host + ".done")
        self.writeDoneToFile(doneFilePath, str(sshstat.returncode))

        logging.info("Setup agent done for host " +
                     self.host + ", exitcode=" + str(sshstat.returncode))
        pass

    def writeLogToFile(self, logFilePath):
        logFile = open(logFilePath, "a+")
        logFile.write(self.ret["log"])
        logFile.close
        pass

    def writeDoneToFile(self, doneFilePath, returncode):
        doneFile = open(doneFilePath, "w+")
        doneFile.write(str(returncode))
        doneFile.close()
        pass
pass
