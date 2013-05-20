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
import pprint
import os
import subprocess
import traceback
from PSSH import PSSH
from PSCP import PSCP

AMBARI_PASSPHRASE_VAR_NAME = "AMBARI_PASSPHRASE"
HOST_BOOTSTRAP_TIMEOUT = 300

def skip_failed_hosts(statuses):
    """ Takes a dictionary <hostname, hoststatus> and returns list of hosts whose status is SUCCESS"""
    res = list(key for key, value in statuses.iteritems() if value[
               "exitstatus"] == 0)
    return res

def unite_statuses(statuses, update):
    """ Takes two dictionaries <hostname, hoststatus> and returns dictionary with united entries (returncode is set
    to the max value per host, logs per host are concatenated)"""
    result = {}
    for key, value in statuses.iteritems():
        if key in update:
            upd_status = update[key]
            res_status = {
                "exitstatus": max(value["exitstatus"], upd_status["exitstatus"]),
                "log": value["log"] + "\n" + upd_status["log"]
            }
            result[key] = res_status
        else:
            result[key] = value
    return result


def get_difference(list1, list2):
    """Takes two lists and returns list filled by elements of list1 that are absent at list2.
    Duplicates are removed too"""
    # res =
    s1 = set(list1)
    s2 = set(list2)
    return list(s1 - s2)


class BootStrapAction:

    """ Runs a BootStrap action (bootstrap or teardown) on a list of hosts"""
    def __init__(self, hosts, user, ssh_key_file, script_dir, boottmpdir,
                 agent_action_path, ambari_server, cluster_os_type, ambari_version,
                 password_file=None):
        self.hostlist = hosts
        self.successive_hostlist = hosts
        self.hostlist_to_remove_password_file = None
        self.user = user
        self.ssh_key_file = ssh_key_file
        self.bootdir = boottmpdir
        self.script_dir = script_dir
        self.agent_action_path = agent_action_path
        self.agent_action_filename = agent_action_path.split('/')[-1]
        self.ambari_server = ambari_server
        self.cluster_os_type = cluster_os_type
        self.ambari_version = ambari_version
        self.password_file = password_file
        self.statuses = None

    # This method is needed  to implement the descriptor protocol (make object
    # to pass self reference to mockups)
    def __get__(self, obj, objtype):
        def _call(*args, **kwargs):
            self(obj, *args, **kwargs)
        return _call

    def is_suse(self):
        if os.path.isfile("/etc/issue"):
            if "suse" in open("/etc/issue").read().lower():
                return True
        return False

    def get_repo_dir(self):
        """ Ambari repo file for Ambari."""
        if self.is_suse():
            return "/etc/zypp/repos.d"
        else:
            return "/etc/yum.repos.d"

    def get_repo_file(self):
        """ Ambari repo file for Ambari."""
        return os.path.join(self.get_repo_dir(), "ambari.repo")

    def get_os_check_script(self):
        return os.path.join(self.script_dir, "os_type_check.sh")

    def get_setup_script(self):
        return os.path.join(self.script_dir, "setupAgent.py")

    def get_password_file(self):
        return "/tmp/host_pass"

    def has_password(self):
        return self.password_file != None and self.password_file != 'null'

    def getMoveRepoFileWithPasswordCommand(self, target_dir):
        return "sudo -S mv /tmp/ambari.repo " + target_dir + " < " + self.get_password_file()

    def getMoveRepoFileWithoutPasswordCommand(self, target_dir):
        return "sudo mv /tmp/ambari.repo " + target_dir

    def get_move_repo_file_command(self, target_dir):
        if self.has_password():
            return self.getMoveRepoFileWithPasswordCommand(target_dir)
        else:
            return self.getMoveRepoFileWithoutPasswordCommand(target_dir)

    OS_CHECK_SCRIPT_REMOTE_LOCATION = "/tmp/os_type_check.sh"

    def copy_os_check_script(self):
        try:
            # Copying the os check script file
            file_to_copy = self.get_os_check_script()
            target = self.OS_CHECK_SCRIPT_REMOTE_LOCATION
            pscp = PSCP(self.successive_hostlist, self.user, self.ssh_key_file,
                        file_to_copy, target, self.bootdir, HOST_BOOTSTRAP_TIMEOUT)
            pscp.run()
            out = pscp.getstatus()
            # Preparing report about failed hosts
            self.successive_hostlist = skip_failed_hosts(out)
            failed = get_difference(self.hostlist, self.successive_hostlist)
            logging.info(
                "Parallel scp returns for os type check script. Failed hosts are: " + str(failed))
            # updating statuses
            self.statuses = out

            if not failed:
                retstatus = 0
            else:
                retstatus = 1
            return retstatus

        except Exception, e:
            logging.info("Traceback " + traceback.format_exc())

    def copy_needed_files(self):
        try:
            # Copying the files
            file_to_copy = self.get_repo_file()
            logging.info("Copying repo file to 'tmp' folder...")
            pscp = PSCP(self.successive_hostlist, self.user, self.ssh_key_file,
                        file_to_copy, "/tmp", self.bootdir, HOST_BOOTSTRAP_TIMEOUT)
            pscp.run()
            out = pscp.getstatus()
            # Preparing report about failed hosts
            failed_current = get_difference(
                self.successive_hostlist, skip_failed_hosts(out))
            self.successive_hostlist = skip_failed_hosts(out)
            failed = get_difference(self.hostlist, self.successive_hostlist)
            logging.info("Parallel scp returns for copying repo file. All failed hosts are: " + str(failed) +
                         ". Failed on last step: " + str(failed_current))
            # updating statuses
            self.statuses = unite_statuses(self.statuses, out)

            logging.info("Moving repo file...")
            target_dir = self.get_repo_dir()
            command = self.get_move_repo_file_command(target_dir)
            pssh = PSSH(self.successive_hostlist, self.user,
                        self.ssh_key_file, command, self.bootdir, HOST_BOOTSTRAP_TIMEOUT)
            pssh.run()
            out = pssh.getstatus()
            # Preparing report about failed hosts
            failed_current = get_difference(
                self.successive_hostlist, skip_failed_hosts(out))
            self.successive_hostlist = skip_failed_hosts(out)
            failed = get_difference(self.hostlist, self.successive_hostlist)
            logging.info("Parallel scp returns for moving repo file. All failed hosts are: " + str(failed) +
                         ". Failed on last step: " + str(failed_current))
            # updating statuses
            self.statuses = unite_statuses(self.statuses, out)

            pscp = PSCP(self.successive_hostlist, self.user, self.ssh_key_file,
                        self.agent_action_path, "/tmp", self.bootdir, HOST_BOOTSTRAP_TIMEOUT)
            pscp.run()
            out = pscp.getstatus()
            # Preparing report about failed hosts
            failed_current = get_difference(
                self.successive_hostlist, skip_failed_hosts(out))
            self.successive_hostlist = skip_failed_hosts(out)
            failed = get_difference(self.hostlist, self.successive_hostlist)
            logging.info("Parallel scp returns for agent script. All failed hosts are: " + str(failed) +
                         ". Failed on last step: " + str(failed_current))
            # updating statuses
            self.statuses = unite_statuses(self.statuses, out)

            if not failed:
                retstatus = 0
            else:
                retstatus = 1
            return retstatus

        except Exception, e:
            logging.info("Traceback " + traceback.format_exc())

    def getambari_version(self):
        if self.ambari_version is None or self.ambari_version == "null":
            return ""
        else:
            return self.ambari_version

    def getRunActionWithPasswordCommand(self):
        return ("sudo -S python /tmp/" + self.agent_action_filename + " " +
                os.environ[AMBARI_PASSPHRASE_VAR_NAME] + " " +
                self.ambari_server + " " + self.getambari_version() + " < " +
                self.get_password_file())

    def getRunActionWithoutPasswordCommand(self):
        return ("sudo python /tmp/" + self.agent_action_filename + " " +
                os.environ[AMBARI_PASSPHRASE_VAR_NAME] + " " +
                self.ambari_server + " " + self.getambari_version())

    def get_run_action_command(self):
        if self.has_password():
            return self.getRunActionWithPasswordCommand()
        else:
            return self.getRunActionWithoutPasswordCommand()

    def run_os_check_script(self):
        logging.info("Running os type check...")
        command = "chmod a+x %s && %s %s" % \
            (self.OS_CHECK_SCRIPT_REMOTE_LOCATION,
                self.OS_CHECK_SCRIPT_REMOTE_LOCATION,  self.cluster_os_type)

        pssh = PSSH(self.successive_hostlist, self.user,
                    self.ssh_key_file, command, self.bootdir, HOST_BOOTSTRAP_TIMEOUT)
        pssh.run()
        out = pssh.getstatus()

        # Preparing report about failed hosts
        failed_current = get_difference(
            self.successive_hostlist, skip_failed_hosts(out))
        self.successive_hostlist = skip_failed_hosts(out)
        failed = get_difference(self.hostlist, self.successive_hostlist)
        logging.info("Parallel ssh returns for setup agent. All failed hosts are: " + str(failed) +
                     ". Failed on last step: " + str(failed_current))

        # updating statuses
        self.statuses = unite_statuses(self.statuses, out)

        if not failed:
            retstatus = 0
        else:
            retstatus = 1

    def run_agent_action(self):
        logging.info("Running agent action...")
        command = self.get_run_action_command()
        pssh = PSSH(self.successive_hostlist, self.user,
                    self.ssh_key_file, command, self.bootdir, HOST_BOOTSTRAP_TIMEOUT)
        pssh.run()
        out = pssh.getstatus()

        # Preparing report about failed hosts
        failed_current = get_difference(
            self.successive_hostlist, skip_failed_hosts(out))
        self.successive_hostlist = skip_failed_hosts(out)
        failed = get_difference(self.hostlist, self.successive_hostlist)
        logging.info("Parallel ssh returns for agent action. All failed hosts are: " + str(failed) +
                     ". Failed on last step: " + str(failed_current))

        # updating statuses
        self.statuses = unite_statuses(self.statuses, out)

        if not failed:
            retstatus = 0
        else:
            retstatus = 1

    def create_done_files(self):
        """ Creates .done files for every host. These files are later read from Java code.
        If .done file for any host is not created, the bootstrap will hang or fail due to timeout"""
        for key, value in self.statuses.iteritems():
            done_file_path = os.path.join(self.bootdir, key + ".done")
            if not os.path.exists(done_file_path):
                done_file = open(done_file_path, "w+")
                done_file.write(str(value["exitstatus"]))
                done_file.close()

    def check_sudo_package(self):
        try:
            """ Checking 'sudo' package on remote hosts """
            command = "rpm -qa | grep sudo"
            pssh = PSSH(
                self.successive_hostlist, self.user, self.ssh_key_file, command, self.bootdir,
                HOST_BOOTSTRAP_TIMEOUT, "Error: Sudo command is not available. Please install the sudo command.")
            pssh.run()
            out = pssh.getstatus()
            # Preparing report about failed hosts
            failed_current = get_difference(
                self.successive_hostlist, skip_failed_hosts(out))
            self.successive_hostlist = skip_failed_hosts(out)
            failed = get_difference(self.hostlist, self.successive_hostlist)
            logging.info("Parallel ssh returns for checking 'sudo' package. All failed hosts are: " + str(failed) +
                         ". Failed on last step: " + str(failed_current))
            # updating statuses
            self.statuses = unite_statuses(self.statuses, out)

            if not failed:
                retstatus = 0
            else:
                retstatus = 1
            return retstatus

        except Exception, e:
            logging.info("Traceback " + traceback.format_exc())

    def copy_password_file(self):
        try:
            # Copying the password file
            logging.info("Copying password file to 'tmp' folder...")
            pscp = PSCP(self.successive_hostlist, self.user, self.ssh_key_file,
                        self.password_file, "/tmp", self.bootdir, HOST_BOOTSTRAP_TIMEOUT)
            pscp.run()
            out = pscp.getstatus()
            # Preparing report about failed hosts
            failed_current = get_difference(
                self.successive_hostlist, skip_failed_hosts(out))
            self.successive_hostlist = skip_failed_hosts(out)
            self.hostlist_to_remove_password_file = self.successive_hostlist
            failed = get_difference(self.hostlist, self.successive_hostlist)
            logging.warn("Parallel scp returns for copying password file. All failed hosts are: " + str(failed) +
                         ". Failed on last step: " + str(failed_current))
            # updating statuses
            self.statuses = unite_statuses(self.statuses, out)

            # Change password file mode to 600
            logging.info("Changing password file mode...")
            target_dir = self.get_repo_dir()
            command = "chmod 600 " + self.get_password_file()
            pssh = PSSH(self.successive_hostlist, self.user,
                        self.ssh_key_file, command, self.bootdir, HOST_BOOTSTRAP_TIMEOUT)
            pssh.run()
            out = pssh.getstatus()
            # Preparing report about failed hosts
            failed_current = get_difference(
                self.successive_hostlist, skip_failed_hosts(out))
            self.successive_hostlist = skip_failed_hosts(out)
            failed = get_difference(self.hostlist, self.successive_hostlist)
            logging.warning("Parallel scp returns for copying password file. All failed hosts are: " + str(failed) +
                            ". Failed on last step: " + str(failed_current))
            # updating statuses
            self.statuses = unite_statuses(self.statuses, out)

            if not failed:
                retstatus = 0
            else:
                retstatus = 1
            return retstatus

        except Exception, e:
            logging.info("Traceback " + traceback.format_exc())
            return 1

    def change_password_file_mode_on_host(self):
        try:
            # Change password file mode to 600
            logging.info("Changing password file mode...")
            target_dir = self.get_repo_dir()
            command = "chmod 600 " + self.get_password_file()
            pssh = PSSH(self.successive_hostlist, self.user,
                        self.ssh_key_file, command, self.bootdir, HOST_BOOTSTRAP_TIMEOUT)
            pssh.run()
            out = pssh.getstatus()
            # Preparing report about failed hosts
            failed_current = get_difference(
                self.successive_hostlist, skip_failed_hosts(out))
            self.successive_hostlist = skip_failed_hosts(out)
            failed = get_difference(self.hostlist, self.successive_hostlist)
            logging.warning("Parallel scp returns for copying password file. All failed hosts are: " + str(failed) +
                            ". Failed on last step: " + str(failed_current))
            # updating statuses
            self.statuses = unite_statuses(self.statuses, out)

            if not failed:
                retstatus = 0
            else:
                retstatus = 1
            return retstatus

        except Exception, e:
            logging.info("Traceback " + traceback.format_exc())
            return 1

    def delete_password_file(self):
        try:
            # Deleting the password file
            logging.info("Deleting password file...")
            target_dir = self.get_repo_dir()
            command = "rm " + self.get_password_file()
            pssh = PSSH(self.hostlist_to_remove_password_file, self.user,
                        self.ssh_key_file, command, self.bootdir, HOST_BOOTSTRAP_TIMEOUT)
            pssh.run()
            out = pssh.getstatus()
            # Preparing report about failed hosts
            failed_current = get_difference(
                self.hostlist_to_remove_password_file, skip_failed_hosts(out))
            self.successive_hostlist = skip_failed_hosts(out)
            failed = get_difference(self.hostlist, self.successive_hostlist)
            logging.warn("Parallel scp returns for deleting password file. All failed hosts are: " + str(failed) +
                         ". Failed on last step: " + str(failed_current))
            # updating statuses
            self.statuses = unite_statuses(self.statuses, out)

            if not failed:
                retstatus = 0
            else:
                retstatus = 1
            return retstatus

        except Exception, e:
            logging.info("Traceback " + traceback.format_exc())
            return 1

    def run(self):
        """ Copy files and run commands on remote hosts """
        ret1 = self.copy_os_check_script()
        logging.info("Copying os type check script finished")
        ret2 = self.run_os_check_script()
        logging.info("Running os type check  finished")
        ret3 = self.check_sudo_package()
        logging.info("Checking 'sudo' package finished")
        ret4 = 0
        ret5 = 0
        if self.has_password():
            ret4 = self.copy_password_file()
            logging.info("Copying password file finished")
            ret5 = self.change_password_file_mode_on_host()
            logging.info("Change password file mode on host finished")
        ret6 = self.copy_needed_files()
        logging.info("Copying files finished")
        ret7 = self.run_agent_action()
        logging.info("Running ssh command finished")
        ret8 = 0
        if self.has_password() and self.hostlist_to_remove_password_file is not None:
            ret8 = self.delete_password_file()
            logging.info("Deleting password file finished")
        retcode = max(ret1, ret2, ret3, ret4, ret5, ret6, ret7, ret8)
        self.create_done_files()
        return retcode


def main(argv=None):
    script_dir = os.path.realpath(os.path.dirname(argv[0]))
    onlyargs = argv[1:]
    if len(onlyargs) < 9:
        sys.stderr.write("Usage: <comma separated hosts> <tmpdir for storage> "
            "<user> <ssh_key_file> <agent action script> <ambari-server name> "
            "<cluster os type> <ambari version> <password_file>\n")
        sys.exit(2)
    # Parse the input
    hostList = onlyargs[0].split(",")
    bootdir = onlyargs[1]
    user = onlyargs[2]
    ssh_key_file = onlyargs[3]
    agent_action_path = onlyargs[4]
    ambari_server = onlyargs[5]
    cluster_os_type = onlyargs[6]
    ambari_version = onlyargs[7]
    password_file = onlyargs[8]

    # ssh doesn't like open files
    stat = subprocess.Popen(
        ["chmod", "600", ssh_key_file], stdout=subprocess.PIPE)

    if password_file != None and password_file != 'null':
        stat = subprocess.Popen(
            ["chmod", "600", password_file], stdout=subprocess.PIPE)

    logging.info("BootStrapping action on hosts " + pprint.pformat(hostList) +
                 "running " + agent_action_path + " using " + script_dir +
                 " cluster primary OS: " + cluster_os_type + " with user '" +
                 user + "' sshKey File " + ssh_key_file + " password File " +
                 password_file + " using tmp dir " + bootdir + " ambari: " +
                 ambari_server + "; ambari version: " + ambari_version)
    bootstrap = BootStrapAction(hostList, user, ssh_key_file, script_dir, bootdir,
                          agent_action_path, ambari_server, cluster_os_type, ambari_version, password_file)
    ret = bootstrap.run()
    # return  ret
    return 0  # Hack to comply with current usage

if __name__ == '__main__':
    logging.basicConfig(level=logging.DEBUG)
    main(sys.argv)
