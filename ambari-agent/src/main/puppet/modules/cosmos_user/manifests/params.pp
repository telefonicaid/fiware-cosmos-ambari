class cosmos_user::params inherits hdp::params {

  if has_key($configuration, 'cosmos-user') {
    $cosmos_user_config = $configuration['cosmos-user']
    $user = $cosmos_user_config['user']
    $password = $cosmos_user_config['password']

    $ssh_public_key = $cosmos_user_config['ssh_public_key']
    $ssh_private_key = $cosmos_user_config['ssh_private_key']
    $ssh_authorized_keys = $cosmos_user_config['ssh_authorized_keys']
  }

  $group = hdp_default('group', 'cosmos')

  $user_home = "/home/${user}"
  $user_ssh_dir = "${user_home}/.ssh"
  
  $ssh_private_key_file ="${user_ssh_dir}/id_rsa"
  $ssh_public_key_file ="${user_ssh_dir}/id_rsa.pub"
  $ssh_authorized_keys_file ="${user_ssh_dir}/authorized_keys"

  $hdfs_user_dir = "/user/${user}"
  $hdfs_user_dir_mode = 700
}
