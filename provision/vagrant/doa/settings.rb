#!/usr/bin/ruby

module DOA
  class Setting
    # Guest machine
    ENVIRONMENT       = 'env'
    HOSTNAME          = 'hostname'
    PROVIDER          = 'provider'
    PROVISIONER       = 'provisioner'
    BOX               = 'box'
    ALIASES           = 'aliases'
    FQDN              = 'fqdn'
    MEMORY            = 'memory'
    CORES             = 'cores'
    WWW_ROOT          = 'www_root'

    # Site
    SITES             = 'sites'
    SITE_WWW_ROOT     = 'wwww_root'
    SITE_STACK        = 'stack'

    # Assets
    WP_ASSET_PLUGIN   = 'plugins'
    WP_ASSET_THEME    = 'themes'
    ASSET_PATH        = 'path'
    ASSET_GIT         = 'git'
    ASSET_WPCLI       = 'wpcli'
    ASSET_EXCLUDE     = 'exclude'
    ASSET_SYNC_MODE   = 'sync_mode'

    # Synchronizing modes
    SYNC_BRSYNC       = 'brsync'
    SYNC_DEFAULT      = 'default'

    # Software
    SW_COUCHDB        = 'couchdb'
    SW_MARIADB        = 'mariadb'
    SW_METEOR         = 'meteor'
    SW_NGINX          = 'nginx'
    SW_PHP            = 'php'
    SW_WP             = 'wordpress'

    # Package managers
    PKG_MNGR_DEBIAN   = 'apt' # Debian, Ubuntu
    PKG_MNGR_RHEL     = 'yum' # Ascendos, CentOS, CloudLinux, Fedora, OEL,
                              # OracleLinux, OVS, PSBM, RedHat, Scientific, SLC
  end
end
