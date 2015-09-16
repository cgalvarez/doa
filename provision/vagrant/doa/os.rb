#!/usr/bin/ruby

module DOA
  module OS
    #Operative systems
    LINUX   = 'Linux'
    UNIX    = 'Unix'
    WINDOWS = 'Windows'
    MAC     = 'Mac'

    # Linux distros
    # -------------
    LINUX_FAMILY_DEBIAN = 'debian'
    LINUX_FAMILY_REDHAT = 'redhat'

    # Ubuntu
    LINUX_UBUNTU    = 'ubuntu'
    UBUNTU_LUCID    = 'lucid'     # 10.04
    UBUNTU_PRECISE  = 'precise'   # 12.04
    UBUNTU_QUANTAL  = 'quantal'   # 12.10
    UBUNTU_SAUCY    = 'saucy'     # 13.10
    UBUNTU_TRUSTY   = 'trusty'    # 14.04
    UBUNTU_UTOPIC   = 'utopic'    # 14.10
    UBUNTU_VIVID    = 'vivid'     # 15.04
    UBUNTU_WILY     = 'wily'      # 15.10
  end
end
