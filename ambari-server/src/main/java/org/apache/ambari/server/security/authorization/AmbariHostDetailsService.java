package org.apache.ambari.server.security.authorization;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.userdetails.User;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;

import java.util.LinkedList;

public class AmbariHostDetailsService implements UserDetailsService {
  private static final Logger log = LoggerFactory.getLogger(AmbariHostDetailsService.class);

  @Override
  public UserDetails loadUserByUsername(String username) throws UsernameNotFoundException {
    log.info("Creating user details for host: " + username);
    return new User(username, "", new LinkedList<GrantedAuthority>());
  }
}
