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

import bootstrap
import time
import subprocess
import os
import logging

from SCP import SCP
from PSCP import PSCP
from SSH import SSH
from PSSH import PSSH
from bootstrap import BootStrapAction
from unittest import TestCase
from subprocess import Popen
from bootstrap import AMBARI_PASSPHRASE_VAR_NAME
from mock.mock import MagicMock, call
from mock.mock import patch
from mock.mock import create_autospec


class TestBootstrap(TestCase):

    def setUp(self):
        logging.basicConfig(level=logging.ERROR)

    def test_return_failed_status_for_hanging_ssh_threads_after_timeout(self):
        forever_hanging_timeout = 5
        SSH.run = lambda self: time.sleep(forever_hanging_timeout)
        pssh = PSSH(["hostname"], "root", "sshKeyFile",
                    "command", "bootdir", timeout=1)
        starttime = time.time()
        pssh.run()
        ret = pssh.getstatus()
        self.assertTrue(ret != {})
        self.assertTrue(time.time() - starttime < forever_hanging_timeout)
        self.assertTrue(ret["hostname"]["log"] == "FAILED")
        self.assertTrue(ret["hostname"]["exitstatus"] == -1)

    def test_return_failed_status_for_hanging_scp_threads_after_timeout(self):
        forever_hanging_timeout = 5
        SCP.run = lambda self: time.sleep(forever_hanging_timeout)
        pscp = PSCP(["hostname"], "root", "sshKeyFile",
                    "inputfile", "remote", "bootdir", timeout=1)
        starttime = time.time()
        pscp.run()
        ret = pscp.getstatus()
        self.assertTrue(ret != {})
        self.assertTrue(time.time() - starttime < forever_hanging_timeout)
        self.assertTrue(ret["hostname"]["log"] == "FAILED")
        self.assertTrue(ret["hostname"]["exitstatus"] == -1)

    @patch.object(SCP, "writeLogToFile")
    @patch.object(SSH, "writeLogToFile")
    @patch.object(SSH, "writeDoneToFile")
    @patch.object(Popen, "communicate")
    def test_return_error_message_for_missing_sudo_package(
            self, communicate_method,
            SSH_writeDoneToFile_method,
            SSH_writeLogToFile_method,
            SCP_writeLogToFile_method):
        SCP_writeLogToFile_method.return_value = None
        SSH_writeLogToFile_method.return_value = None
        SSH_writeDoneToFile_method.return_value = None
        communicate_method.return_value = ("", "")
        bootstrap = BootStrapAction(
            ["hostname"], "root", "sshKeyFile", "scriptDir", "bootdir", "setupAgentFile", "ambariServer", "centos6", None)
        bootstrap.statuses = {
            "hostname": {
            "exitstatus": 0,
            "log": ""
            }
        }
        ret = bootstrap.check_sudo_package()
        self.assertTrue("Error: Sudo command is not available. Please install the sudo command." in bootstrap.statuses[
                        "hostname"]["log"])

    @patch.object(SCP, "writeLogToFile")
    @patch.object(SSH, "writeLogToFile")
    @patch.object(SSH, "writeDoneToFile")
    @patch.object(Popen, "communicate")
    @patch.object(BootStrapAction, "create_done_files")
    @patch.object(BootStrapAction, "delete_password_file")
    @patch.object(BootStrapAction, "change_password_file_mode_on_host")
    def test_copy_and_delete_password_file_methods_are_called_for_user_with_password(
            self,
            change_password_file_mode_on_host_method,
            delete_password_file_method,
            create_done_files_method,
            communicate_method,
            SSH_writeDoneToFile_method,
            SSH_writeLogToFile_method,
            SCP_writeLogToFile_method):
        SCP_writeLogToFile_method.return_value = None
        SSH_writeLogToFile_method.return_value = None
        SSH_writeDoneToFile_method.return_value = None
        communicate_method.return_value = ("", "")
        create_done_files_method.return_value = None

        delete_password_file_method.return_value = 0

        change_password_file_mode_on_host_method.return_value = 0

        os.environ[AMBARI_PASSPHRASE_VAR_NAME] = ""
        bootstrap = BootStrapAction(
            ["hostname"], "user", "sshKeyFile", "scriptDir",
            "bootdir", "setupAgentFile", "ambariServer", "centos6", None, "passwordFile")

        def side_effect():
            bootstrap.copy_password_file_called = True
            bootstrap.hostlist_to_remove_password_file = ["hostname"]
            return 0
        bootstrap.copy_password_file = side_effect
        ret = bootstrap.run()
        self.assertTrue(bootstrap.copy_password_file_called)
        self.assertTrue(delete_password_file_method.called)
        self.assertTrue(change_password_file_mode_on_host_method.called)

    @patch.object(SCP, "writeLogToFile")
    @patch.object(SSH, "writeLogToFile")
    @patch.object(SSH, "writeDoneToFile")
    @patch.object(Popen, "communicate")
    @patch.object(BootStrapAction, "create_done_files")
    @patch.object(BootStrapAction, "delete_password_file")
    @patch.object(BootStrapAction, "change_password_file_mode_on_host")
    def test_copy_and_delete_password_file_methods_are_not_called_for_passwordless_user(
            self,
            change_password_file_mode_on_host_method,
            delete_password_file_method,
            create_done_files_method,
            communicate_method,
            SSH_writeDoneToFile_method,
            SSH_writeLogToFile_method,
            SCP_writeLogToFile_method):
        SCP_writeLogToFile_method.return_value = None
        SSH_writeLogToFile_method.return_value = None
        SSH_writeDoneToFile_method.return_value = None
        communicate_method.return_value = ("", "")
        create_done_files_method.return_value = None

        delete_password_file_method.return_value = 0
        change_password_file_mode_on_host_method.return_value = 0

        os.environ[AMBARI_PASSPHRASE_VAR_NAME] = ""
        bootstrap = BootStrapAction(
            ["hostname"], "user", "sshKeyFile", "scriptDir", "bootdir", "setupAgentFile", "ambariServer", "centos6", None)
        bootstrap.copy_password_file_called = False

        def side_effect():
            bootstrap.copy_password_file_called = True
            bootstrap.hostlist_to_remove_password_file = ["hostname"]
            return 0
        bootstrap.copy_password_file = side_effect
        ret = bootstrap.run()
        self.assertFalse(bootstrap.copy_password_file_called)
        self.assertFalse(delete_password_file_method.called)
        self.assertFalse(change_password_file_mode_on_host_method.called)

    @patch.object(SCP, "writeLogToFile")
    @patch.object(SSH, "writeLogToFile")
    @patch.object(SSH, "writeDoneToFile")
    @patch.object(Popen, "communicate")
    @patch.object(BootStrapAction, "create_done_files")
    @patch.object(BootStrapAction, "getRunActionWithPasswordCommand")
    @patch.object(BootStrapAction, "getMoveRepoFileWithPasswordCommand")
    def test_commands_with_password_are_called_for_user_with_password(
            self, getMoveRepoFileWithPasswordCommand_method,
            getRunActionWithPasswordCommand_method,
            create_done_files_method,
            communicate_method,
            SSH_writeDoneToFile_method,
            SSH_writeLogToFile_method,
            SCP_writeLogToFile_method):
        SCP_writeLogToFile_method.return_value = None
        SSH_writeLogToFile_method.return_value = None
        SSH_writeDoneToFile_method.return_value = None
        communicate_method.return_value = ("", "")
        create_done_files_method.return_value = None

        getRunActionWithPasswordCommand_method.return_value = ""
        getMoveRepoFileWithPasswordCommand_method.return_value = ""

        os.environ[AMBARI_PASSPHRASE_VAR_NAME] = ""
        bootstrap = BootStrapAction(
            ["hostname"], "user", "sshKeyFile", "scriptDir",
            "bootdir", "setupAgentFile", "ambariServer", "centos6", None, "passwordFile")
        ret = bootstrap.run()
        self.assertTrue(getRunActionWithPasswordCommand_method.called)
        self.assertTrue(getMoveRepoFileWithPasswordCommand_method.called)

    @patch.object(SCP, "writeLogToFile")
    @patch.object(SSH, "writeLogToFile")
    @patch.object(SSH, "writeDoneToFile")
    @patch.object(Popen, "communicate")
    @patch.object(BootStrapAction, "create_done_files")
    @patch.object(BootStrapAction, "getRunActionWithoutPasswordCommand")
    @patch.object(BootStrapAction, "getMoveRepoFileWithoutPasswordCommand")
    def test_commands_without_password_are_called_for_passwordless_user(
            self, getMoveRepoFileWithoutPasswordCommand_method,
            getRunActionWithoutPasswordCommand_method,
            create_done_files_method,
            communicate_method,
            SSH_writeDoneToFile_method,
            SSH_writeLogToFile_method,
            SCP_writeLogToFile_method):
        SCP_writeLogToFile_method.return_value = None
        SSH_writeLogToFile_method.return_value = None
        SSH_writeDoneToFile_method.return_value = None
        communicate_method.return_value = ("", "")
        create_done_files_method.return_value = None

        getRunActionWithoutPasswordCommand_method.return_value = ""
        getMoveRepoFileWithoutPasswordCommand_method.return_value = ""

        os.environ[AMBARI_PASSPHRASE_VAR_NAME] = ""
        bootstrap = BootStrapAction(
            ["hostname"], "user", "sshKeyFile", "scriptDir", "bootdir", "setupAgentFile", "ambariServer", "centos6", None)
        ret = bootstrap.run()
        self.assertTrue(getRunActionWithoutPasswordCommand_method.called)
        self.assertTrue(getMoveRepoFileWithoutPasswordCommand_method.called)

    @patch.object(BootStrapAction, "run_agent_action")
    @patch.object(BootStrapAction, "copy_needed_files")
    @patch.object(BootStrapAction, "check_sudo_package")
    @patch.object(BootStrapAction, "run_os_check_script")
    @patch.object(BootStrapAction, "copy_os_check_script")
    @patch.object(BootStrapAction, "create_done_files")
    def test_os_check_performed(
            self, create_done_files_method, copy_os_check_script_method,
            run_os_check_script_method, check_sudo_package_method,
            copy_needed_files_method, run_agent_action_method):
        create_done_files_method.return_value = None

        copy_os_check_script_method.return_value = 0
        run_os_check_script_method.return_value = 0
        check_sudo_package_method.return_value = 0
        copy_needed_files_method.return_value = 0
        run_agent_action_method.return_value = 0

        os.environ[AMBARI_PASSPHRASE_VAR_NAME] = ""
        bootstrap = BootStrapAction(
            ["hostname"], "user", "sshKeyFile", "scriptDir",
            "bootdir", "setupAgentFile", "ambariServer",
            "centos6", None)
        ret = bootstrap.run()
        self.assertTrue(copy_os_check_script_method.called)
        self.assertTrue(run_os_check_script_method.called)
        self.assertTrue(ret == 0)

    @patch.object(PSCP, "run")
    @patch.object(PSCP, "getstatus")
    def test_copy_os_check_script(self, getstatus_method, run_method):
        getstatus_method.return_value = {
            "hostname": {
            "exitstatus": 0,
            "log": ""
            }
        }
        os.environ[AMBARI_PASSPHRASE_VAR_NAME] = ""
        bootstrap = BootStrapAction(
            ["hostname"], "user", "sshKeyFile", "scriptDir",
            "bootdir", "setupAgentFile", "ambariServer",
            "centos6", None)
        res = bootstrap.copy_os_check_script()
        self.assertTrue(run_method.called)
        self.assertTrue(getstatus_method.called)
        self.assertTrue(res == 0)
        pass

    @patch.object(PSSH, "run")
    @patch.object(PSSH, "getstatus")
    def test_run_os_check_script_success(self, getstatus_method, run_method):
        good_stats = {
            "hostname": {
            "exitstatus": 0,
            "log": ""
            }
        }
        getstatus_method.return_value = good_stats
        os.environ[AMBARI_PASSPHRASE_VAR_NAME] = ""
        bootstrap = BootStrapAction(
            ["hostname"], "user", "sshKeyFile", "scriptDir",
            "bootdir", "setupAgentFile", "ambariServer",
            "centos6", None)
        bootstrap.statuses = good_stats
        bootstrap.run_os_check_script()

        self.assertTrue(run_method.called)
        self.assertTrue(getstatus_method.called)
        self.assertTrue("hostname" in bootstrap.successive_hostlist)
        pass

    @patch.object(PSSH, "run")
    @patch.object(PSSH, "getstatus")
    def test_run_os_check_script_fail(self, getstatus_method, run_method):
        good_stats = {
            "hostname": {
            "exitstatus": 1,
            "log": ""
            }
        }
        getstatus_method.return_value = good_stats
        os.environ[AMBARI_PASSPHRASE_VAR_NAME] = ""
        bootstrap = BootStrapAction(
            ["hostname"], "user", "sshKeyFile", "scriptDir",
            "bootdir", "setupAgentFile", "ambariServer",
            "centos6", None)
        bootstrap.statuses = good_stats
        bootstrap.run_os_check_script()

        self.assertTrue(run_method.called)
        self.assertTrue(getstatus_method.called)
        self.assertTrue("hostname" not in bootstrap.successive_hostlist)
        pass

    @patch.object(SCP, "writeLogToFile")
    @patch.object(SSH, "writeLogToFile")
    @patch.object(SSH, "writeDoneToFile")
    @patch.object(Popen, "communicate")
    @patch.object(BootStrapAction, "create_done_files")
    def test_run_setup_agent_command_ends_with_project_version(
            self, create_done_files_method,
            communicate_method,
            SSH_writeDoneToFile_method,
            SSH_writeLogToFile_method,
            SCP_writeLogToFile_method):
        SCP_writeLogToFile_method.return_value = None
        SSH_writeLogToFile_method.return_value = None
        SSH_writeDoneToFile_method.return_value = None
        communicate_method.return_value = ("", "")
        create_done_files_method.return_value = None

        os.environ[AMBARI_PASSPHRASE_VAR_NAME] = ""
        version = "1.1.1"
        bootstrap = BootStrapAction(
            ["hostname"], "user", "sshKeyFile", "scriptDir",
            "bootdir", "setupAgentFile", "ambariServer", "centos6", version)
        runSetupCommand = bootstrap.get_run_action_command()
        self.assertTrue(runSetupCommand.endswith(version))

    @patch.object(SCP, "writeLogToFile")
    @patch.object(SSH, "writeLogToFile")
    @patch.object(SSH, "writeDoneToFile")
    @patch.object(Popen, "communicate")
    @patch.object(BootStrapAction, "create_done_files")
    def test_agent_setup_command_without_project_version(
            self, create_done_files_method,
            communicate_method,
            SSH_writeDoneToFile_method,
            SSH_writeLogToFile_method,
            SCP_writeLogToFile_method):
        SCP_writeLogToFile_method.return_value = None
        SSH_writeLogToFile_method.return_value = None
        SSH_writeDoneToFile_method.return_value = None
        communicate_method.return_value = ("", "")
        create_done_files_method.return_value = None

        os.environ[AMBARI_PASSPHRASE_VAR_NAME] = ""
        version = None
        bootstrap = BootStrapAction(
            ["hostname"], "user", "sshKeyFile", "scriptDir",
            "bootdir", "setupAgentFile", "ambariServer", "centos6", version)
        runSetupCommand = bootstrap.get_run_action_command()
        self.assertTrue(runSetupCommand.endswith("ambariServer "))

    @patch.object(BootStrapAction, "create_done_files")
    @patch.object(PSCP, "getstatus")
    @patch.object(PSCP, "run")
    @patch.object(PSSH, "getstatus")
    @patch.object(PSSH, "run")
    def test_os_check_fail_fails_bootstrap_execution(
            self, pssh_run_method, pssh_getstatus_method,
            pscp_run_method, pscp_getstatus_method, create_done_files_method):

        c6hstr = "cent6host"
        c5hstr = "cent5host"

        def pscp_statuses():
            yield {  # copy_os_check_script call
                c6hstr: {
                    "exitstatus": 0,
                    "log": ""
                },
                c5hstr: {
                    "exitstatus": 0,
                    "log": ""
                },
            }
            while True:   # Next calls
                d = {}
                for host in bootstrap.successive_hostlist:
                    d[host] = {
                        "exitstatus": 0,
                        "log": ""
                    }
                yield d

        def pssh_statuses():
            yield {  # run_os_check_script call
                c6hstr: {
                    "exitstatus": 0,
                    "log": ""
                },
                c5hstr: {
                    "exitstatus": 1,
                    "log": ""
                },
            }
            while True:   # Next calls
                d = {}
                for host in bootstrap.successive_hostlist:
                    d[host] = {
                        "exitstatus": 0,
                        "log": ""
                    }
                yield d

        pscp_getstatus_method.side_effect = pscp_statuses().next
        pssh_getstatus_method.side_effect = pssh_statuses().next

        os.environ[AMBARI_PASSPHRASE_VAR_NAME] = ""
        bootstrap = BootStrapAction(
            [c6hstr, c5hstr], "user", "sshKeyFile", "scriptDir",
                              "bootdir", "setupAgentFile", "ambariServer",
                              "centos6", None)
        ret = bootstrap.run()

        self.assertTrue(c5hstr not in bootstrap.successive_hostlist)
        self.assertTrue(c6hstr in bootstrap.successive_hostlist)
        self.assertTrue(pssh_run_method.call_count >= 2)
        self.assertTrue(pssh_getstatus_method.call_count >= 2)
        self.assertTrue(ret == 1)
