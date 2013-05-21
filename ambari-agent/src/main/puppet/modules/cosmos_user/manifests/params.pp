class cosmos_user::params inherits hdp::params {

  if has_key($configuration, 'cosmos-user') {
    $cosmos_user_config = $configuration['cosmos-user']
    $user = $cosmos_user_config['user']
    $master = $cosmos_user_config['master']

    $ssh_master_public_key = $cosmos_user_config['ssh_master_public_key']
    $ssh_master_private_key = $cosmos_user_config['ssh_master_private_key']
    $ssh_master_authorized_keys = $cosmos_user_config['ssh_master_authorized_keys']
    $ssh_slave_authorized_keys = $cosmos_user_config['ssh_slave_authorized_keys']
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
