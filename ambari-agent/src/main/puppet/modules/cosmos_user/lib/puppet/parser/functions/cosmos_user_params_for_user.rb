# Telefónica Digital - Product Development and Innovation
#
# THIS CODE AND INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND,
# EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE.
#
# Copyright (c) Telefónica Investigación y Desarrollo S.A.U.
# All rights reserved.

module Puppet::Parser::Functions
  newfunction(:cosmos_user_params_for_user, :type => :rvalue) do |args|
    userIndex = args[0]
    allUserParams = args[1]
    thisUserParams = Hash[
        Hash[
            allUserParams.select {|key, _value| key =~ (/user#{userIndex}_.*/)}
        ].map{|key, value| [key.match(/user#{userIndex}_(.*)/)[1], value]}
    ]

    thisUserParams['user_home'] = "/home/#{thisUserParams['username']}"
    thisUserParams['user_ssh_dir'] = "#{thisUserParams['user_home']}/.ssh"

    thisUserParams['ssh_private_key_file'] = "#{thisUserParams['user_ssh_dir']}/id_rsa"
    thisUserParams['ssh_public_key_file'] = "#{thisUserParams['user_ssh_dir']}/id_rsa.pub"
    thisUserParams['ssh_authorized_keys_file'] = "#{thisUserParams['user_ssh_dir']}/authorized_keys"
    thisUserParams['hdfs_user_dir'] = "/user/#{thisUserParams['username']}"
    thisUserParams['sudoer_file'] = "/etc/sudoers.d/100_#{thisUserParams['username']}"
    thisUserParams
  end
end
