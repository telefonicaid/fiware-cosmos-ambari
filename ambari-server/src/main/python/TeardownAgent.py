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

import sys
import logging
import os
import subprocess

def exec_os_command(os_command):
    os_stat = subprocess.Popen(os_command, stdout=subprocess.PIPE)
    return {
        "exitstatus": os_stat.returncode,
        "log": os_stat.communicate(0)
    }


def is_suse():
    """Return true if the current OS is Suse Linux, false otherwise"""
    if os.path.isfile("/etc/issue"):
        if "suse" in open("/etc/issue").read().lower():
            return True
    return False


def teardown_agent_suse():
    """ Run zypper remove"""
    zypper_command = ["zypper", "remove", "-y", "ambari-agent"]
    return exec_os_command(zypper_command)['exitstatus']


def teardown_agent():
    """ Run yum remove"""
    rpm_command = ["yum", "-y", "remove", "ambari-agent"]
    return exec_os_command(rpm_command)['exitstatus']

def parse_args(argv):
    onlyargs = argv[1:]
    pass_phrase = onlyargs[0]
    hostname = onlyargs[1]
    project_version = None
    if len(onlyargs) > 2:
        project_version = onlyargs[2]

    if project_version is None or project_version == "null":
        project_version = ""

    if project_version != "":
        project_version = "-" + project_version
    return (pass_phrase, hostname, project_version)


def main(argv=None):
    script_dir = os.path.realpath(os.path.dirname(argv[0]))
    (pass_phrase, hostname, project_version) = parse_args(argv)

    exec_os_command(["ambari-agent", "stop"])
    exec_os_command(["ambari-agent", "unregister"])

    if is_suse():
        exit_code = teardown_agent_suse()
    else:
        exit_code = teardown_agent()

    sys.exit(exit_code)

if __name__ == '__main__':
    logging.basicConfig(level=logging.DEBUG)
    main(sys.argv)
